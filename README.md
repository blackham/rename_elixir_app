# Rename Elixir Project

  wget https://raw.githubusercontent.com/blackham/rename_elixir_app/rename.sh
  chmod +x rename.sh
  cd /to/your/project
  
  # Backup first
  cd ..
  tar zvfc project.tgz project

  # Now we can break it
  cd project
  cp /path/to/rename.sh ./
  ./rename NewProjectName new_project_name
