use anyhow::{anyhow, Result};
use clap::{Parser, Subcommand};
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use std::process::Command;

const GITHUB_RAW_URL: &str = "https://raw.githubusercontent.com/github/gitignore/main";
const GITHUB_API_URL: &str = "https://api.github.com/repos/github/gitignore/contents";

#[derive(Parser)]
#[command(name = "gitignore")]
#[command(about = "Download .gitignore files from github/gitignore repository")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

    #[arg(help = "Name of the gitignore template to download")]
    template: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    #[command(name = "ls", about = "List all available gitignore templates")]
    List,
}

#[derive(serde::Deserialize)]
struct GitHubFile {
    name: String,
    #[serde(rename = "type")]
    file_type: String,
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Some(Commands::List) => {
            list_templates()?;
        }
        None => {
            if let Some(template) = cli.template {
                download_template(&template)?;
            } else {
                interactive_selection()?;
            }
        }
    }

    Ok(())
}

fn list_templates() -> Result<()> {
    let templates = fetch_templates()?;
    for template in templates {
        println!("{}", template);
    }
    Ok(())
}

fn fetch_templates() -> Result<Vec<String>> {
    let client = reqwest::blocking::Client::new();
    let response = client
        .get(GITHUB_API_URL)
        .header("User-Agent", "gitignore-cli")
        .send()?;

    if !response.status().is_success() {
        return Err(anyhow!("Failed to fetch templates: {}", response.status()));
    }

    let files: Vec<GitHubFile> = response.json()?;
    let mut templates = Vec::new();

    for file in files {
        if file.file_type == "file" && file.name.ends_with(".gitignore") {
            let template_name = file.name.strip_suffix(".gitignore").unwrap().to_string();
            templates.push(template_name);
        }
    }

    templates.sort();
    Ok(templates)
}

fn download_template(template: &str) -> Result<()> {
    let url = format!("{}/{}.gitignore", GITHUB_RAW_URL, template);
    let client = reqwest::blocking::Client::new();
    
    let response = client
        .get(&url)
        .header("User-Agent", "gitignore-cli")
        .send()?;

    if !response.status().is_success() {
        return Err(anyhow!("Template '{}' not found", template));
    }

    let content = response.text()?;

    if Path::new(".gitignore").exists() {
        print!(".gitignore already exists. Overwrite? (y/N): ");
        io::stdout().flush()?;
        
        let mut input = String::new();
        io::stdin().read_line(&mut input)?;
        
        if !input.trim().to_lowercase().starts_with('y') {
            println!("Aborted.");
            return Ok(());
        }
    }

    fs::write(".gitignore", content)?;
    println!("Downloaded {} template to .gitignore", template);
    
    Ok(())
}

fn interactive_selection() -> Result<()> {
    if !is_fzf_installed() {
        println!("fzf not found. Install fzf for interactive template selection.");
        println!("Usage: gitignore <template_name> or gitignore ls");
        return Ok(());
    }

    let templates = fetch_templates()?;
    let templates_str = templates.join("\n");

    let mut fzf = Command::new("fzf")
        .arg("--prompt=Select gitignore template: ")
        .arg("--height=40%")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .spawn()?;

    if let Some(stdin) = fzf.stdin.as_mut() {
        stdin.write_all(templates_str.as_bytes())?;
    }

    let output = fzf.wait_with_output()?;

    if output.status.success() {
        let selected = String::from_utf8(output.stdout)?;
        let selected = selected.trim();
        
        if !selected.is_empty() {
            download_template(selected)?;
        }
    }

    Ok(())
}

fn is_fzf_installed() -> bool {
    Command::new("fzf")
        .arg("--version")
        .output()
        .map(|output| output.status.success())
        .unwrap_or(false)
}