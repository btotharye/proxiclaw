# Getting Started with OpenClaw

Guide for using OpenClaw as your AI coding assistant.

## Table of Contents

- [First Steps](#first-steps)
- [Understanding OpenClaw](#understanding-openclaw)
- [Basic Usage](#basic-usage)
- [Git Repository Access](#git-repository-access)
- [Skills and Capabilities](#skills-and-capabilities)
- [Workspace Configuration](#workspace-configuration)
- [Best Practices](#best-practices)
- [Examples](#examples)

## First Steps

### 1. Access the Control UI

After completing authentication, you should see the OpenClaw Control UI:

1. Open your browser to: `https://<vm-ip>:18789`
2. The chat interface will be displayed
3. Start a conversation to test connectivity

### 2. Verify Setup

Test that OpenClaw can respond:

```
You: Hello! Can you tell me what you can do?
```

OpenClaw should respond with its capabilities. If you get an error about "No API key found":

**If deployed with Ansible:** API keys should be auto-configured. Check they're set in `ansible/inventory/group_vars/all.yml` and re-run the playbook.

**If deployed manually:** Configure API keys:

```bash
ssh ubuntu@<vm-ip>
cd /opt/openclaw
docker compose exec openclaw-gateway openclaw configure --section model
# Follow the prompts to add your Anthropic and OpenAI API keys
```

**Other issues:**

- Check logs for errors: `ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 --tail 50"`
- Verify API keys in .env: See [COMMON_COMMANDS.md](COMMON_COMMANDS.md#check-api-keys)

## Understanding OpenClaw

OpenClaw is an AI assistant that can:

- **Write and modify code** across multiple languages
- **Execute commands** on its host system (with approval)
- **Browse files** in its workspace
- **Use tools** like git, npm, pip, docker, etc.
- **Access the web** to fetch documentation
- **Run code** and see the results
- **Work with git repositories** to push/pull changes

### Architecture

```
┌─────────────────────┐
│   Your Browser      │
│  (Control UI)       │
└──────────┬──────────┘
           │
           │ WebSocket
           ▼
┌─────────────────────┐
│   Gateway           │
│  (Manages sessions) │
└──────────┬──────────┘
           │
           │ API Calls
           ▼
┌─────────────────────┐
│   AI Provider       │
│  (Claude/OpenAI)    │
└─────────────────────┘
           │
           │ Tools/Skills
           ▼
┌─────────────────────┐
│   Workspace         │
│  (~/.openclaw/      │
│   workspace/)       │
└─────────────────────┘
```

## Basic Usage

### Starting a Conversation

Simply type your request in the chat interface. Be specific about what you want:

**Good:**

```
Create a Python script that reads a CSV file and calculates the average of the
'price' column, then saves the result to a new file called 'average.txt'
```

**Less Good:**

```
Write a Python script
```

### Multi-turn Conversations

OpenClaw maintains context in conversations:

```
You: Create a Node.js Express server with a health check endpoint
OpenClaw: [creates server.js]

You: Now add user authentication with JWT
OpenClaw: [modifies server.js to add auth]

You: Write tests for the authentication
OpenClaw: [creates test file]
```

### Command Execution

OpenClaw can execute commands with your approval:

```
You: Install the requests library for Python
OpenClaw: I'll run: pip install requests
[Asks for approval]
```

**Approval Modes:**

- **Interactive:** Approve each command (default, safest)
- **Auto-approve:** Automatically approve trusted commands (configure in settings)

## Git Repository Access

### Option 1: Clone Repositories

Tell OpenClaw to clone repositories directly:

```
You: Clone the repository https://github.com/username/project.git into the workspace
```

OpenClaw will:

1. Clone the repository
2. Navigate into it
3. Be ready to work on the code

### Option 2: Mount Git Repository

Mount a local git repository into OpenClaw's workspace:

```bash
# SSH into the VM
ssh ubuntu@<vm-ip>

# Clone your repository into the workspace
cd ~/.openclaw/workspace/
git clone https://github.com/username/project.git
```

Now in OpenClaw:

```
You: What files are in the project directory?
```

### Setting Up Git Credentials

For private repositories, configure git credentials on the VM:

```bash
ssh ubuntu@<vm-ip>

# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Option 1: SSH keys (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"
cat ~/.ssh/id_ed25519.pub  # Add this to GitHub/GitLab

# Configure SSH for GitHub
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config ~/.ssh/id_ed25519

# Test the connection
ssh -T git@github.com  # Should show successful authentication

# Option 2: Personal Access Token
git config --global credential.helper store
# Then clone a repo, enter token when prompted
```

**Note for Ansible deployments:** The Ansible playbook automatically mounts your `~/.ssh` directory and `~/.gitconfig` into the OpenClaw container. Once you configure SSH keys on the VM, OpenClaw will immediately have access to them without any additional setup.

### Working with Git

Once a repository is accessible, you can ask OpenClaw to:

```
You: List all files in the project

You: Show me the main function in app.py

You: Create a new branch called 'feature/new-endpoint'

You: Add a new API endpoint to handle user registration

You: Run the tests to make sure everything works

You: Commit these changes with message "Add user registration endpoint"

You: Push the changes to the remote repository
```

### Git Workflow Example

Complete workflow for making changes:

```
You:
1. Clone https://github.com/username/myproject.git
2. Create a new branch called feature/add-logging
3. Add logging to all functions in utils.py
4. Run the tests
5. If tests pass, commit and push

OpenClaw: [Executes each step with approvals]
```

## Skills and Capabilities

OpenClaw comes with various skills enabled by default:

### File System

- Read, write, create, delete files
- Search files with grep/ripgrep
- Navigate directories
- View file contents

### Development Tools

- **Node.js/npm:** Install packages, run scripts
- **Python/pip:** Install packages, run scripts
- **Docker:** Build, run containers
- **Git:** All git operations

### Code Editing

- Create new files
- Modify existing code
- Refactor functions
- Add comments/documentation

### Web Access

- Fetch URLs to read documentation
- Download files
- Access APIs

### System Commands

- Run shell commands (with approval)
- Check system information
- Monitor processes

### Checking Available Skills

```bash
ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw skills list"
```

## Workspace Configuration

### Default Workspace

By default, OpenClaw uses: `/home/ubuntu/.openclaw/workspace/`

This is mounted into the container at: `/home/node/.openclaw/workspace/`

### Organizing Your Workspace

Create a structure for different projects:

```bash
ssh ubuntu@<vm-ip>
cd ~/.openclaw/workspace/

# Create project directories
mkdir -p projects/web-apps
mkdir -p projects/scripts
mkdir -p projects/experiments
```

Then in OpenClaw:

```
You: Navigate to projects/web-apps and list the contents
```

### Workspace Persistence

Everything in the workspace persists across container restarts. Your code and files are safe.

### Sharing Files with Workspace

Copy files from your local machine to the workspace:

```bash
# From your local machine
scp ./myfile.py ubuntu@<vm-ip>:~/.openclaw/workspace/
```

## Best Practices

### 1. Be Specific

**Good:**

```
Create a REST API in Python using Flask with these endpoints:
- GET /users - list all users
- POST /users - create a new user
- GET /users/{id} - get user by ID
Include error handling and return JSON responses
```

**Less Good:**

```
Make an API
```

### 2. Review Before Approving

When OpenClaw wants to run commands, review them:

- Read the command carefully
- Understand what it will do
- Approve if safe, reject if unsure

### 3. Use Git Branches

Always work in branches when modifying repositories:

```
You: Create a new branch for this work
```

### 4. Test Before Committing

```
You: Run the tests to verify the changes work correctly
```

### 5. Provide Context

The more context you provide, the better results:

```
You: This is a Django project using PostgreSQL. I need to add a new model
for tracking user sessions. The model should include user_id, session_token,
created_at, and expires_at fields.
```

### 6. Iterate

Don't expect perfection on first try:

```
You: The function works but it's slow for large datasets. Can you optimize it?
```

### 7. Ask for Explanations

```
You: Explain what this function does and why you chose this approach
```

## Examples

### Example 1: Create a New Project

```
You: Create a new Python project called "data-processor" with the following structure:
- src/ directory for source code
- tests/ directory for tests
- requirements.txt with pandas and requests
- README.md with project description
- .gitignore for Python projects
- A main.py file with a basic CLI interface using argparse
```

### Example 2: Debug an Issue

```
You: I have a bug in the process_data function in src/processor.py. When I pass
an empty list, it crashes. Can you:
1. Review the function
2. Identify the issue
3. Fix it
4. Add error handling
5. Write a test case for this scenario
```

### Example 3: Add a Feature

```
You: Add a caching layer to the API using Redis:
1. Install the redis-py library
2. Create a cache.py module with get/set functions
3. Modify the /users endpoint to check cache first
4. Set cache expiry to 5 minutes
5. Update the README with Redis setup instructions
```

### Example 4: Refactoring

```
You: The api/routes.py file is getting too large (over 500 lines). Refactor it by:
1. Separating routes into logical modules (users.py, auth.py, posts.py)
2. Keep the common setup in routes.py
3. Update imports in app.py
4. Ensure all tests still pass
```

### Example 5: Documentation

```
You: Add comprehensive docstrings to all functions in utils/ directory following
the Google Python Style Guide. Include:
- Function description
- Args with types
- Returns with type
- Raises (if applicable)
- Example usage
```

### Example 6: CI/CD Setup

```
You: Set up GitHub Actions for this project:
1. Create .github/workflows/test.yml
2. Run tests on push and PR
3. Test on Python 3.9, 3.10, and 3.11
4. Check code formatting with black
5. Run linting with pylint
6. Badge in README showing build status
```

## Advanced Features

### Working with Multiple Files

```
You: Refactor the authentication system by:
1. Creating a new auth/ directory
2. Moving auth-related functions from utils.py
3. Creating separate modules for jwt_handler.py, validators.py, and models.py
4. Updating all imports across the project
5. Adding type hints to all functions
```

### Environment Configuration

```
You: Create a .env.example file with all required environment variables for
this project, and update config.py to load them using python-dotenv
```

### Database Migrations

```
You: Create an Alembic migration to add an 'email_verified' boolean field
to the users table, defaulting to False
```

## Getting Help

### In OpenClaw

```
You: What can you help me with?
You: How do I [specific task]?
You: Show me examples of [specific feature]
```

### Documentation

- OpenClaw CLI: `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose exec openclaw-gateway openclaw --help"`
- Common Commands: [COMMON_COMMANDS.md](COMMON_COMMANDS.md)
- SSL Setup: [SSL_SETUP.md](SSL_SETUP.md)

### Troubleshooting

If OpenClaw isn't responding:

1. **Check the connection:** Is the WebSocket connected? (Look for status indicator in UI)
2. **Check API keys:** Are they configured correctly?
3. **Check logs:** `ssh ubuntu@<vm-ip> "docker logs openclaw-openclaw-gateway-1 --tail 50"`
4. **Check rate limits:** Have you hit API rate limits? (Check provider dashboard)
5. **Restart if needed:** `ssh ubuntu@<vm-ip> "cd /opt/openclaw && docker compose restart"`

## Next Steps

Now that you're familiar with OpenClaw:

1. **Clone your first project** and try modifying some code
2. **Create a new project** from scratch with OpenClaw's help
3. **Set up git credentials** for seamless repository access
4. **Explore different models** to find the best cost/performance balance
5. **Experiment with different prompting styles** to get better results

Happy coding with OpenClaw! 🦞
