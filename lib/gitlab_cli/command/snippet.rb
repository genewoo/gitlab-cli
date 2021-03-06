module GitlabCli
  module Command
    class Snippet < Thor
  map "save" => "download"

  def self.banner(task, namespace = true, subcommand = true)
    "#{basename} #{task.formatted_usage(self, true, subcommand)}"
  end
  
  # ADD
  desc "add [PROJECT] [FILE] [OPTIONS]", "add a snippet"
  long_desc <<-D
    Add a snippet to a project.  You may specify a file to create a snippet from or you may pipe content from cat.
    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id.
   
    $ gitlab snippet add namespace/project file1.txt

    $ cat file1.txt | gitlab snippet add namespace/project
  D
  option :title, :desc => "The title to use for the new snippet", :required => true, :type => :string, :aliases => ["-t"]
  option :file_name, :desc => "A file name for this snippet", :required => true, :type => :string, :aliases => ["-n", "-f"]  
  def add(project, file=nil)
    snippet = GitlabCli::Util::Snippet.create(project, options['title'], options['file_name'], file)

    printf "Snippet created.\nID: %s\nURL: %s\n", snippet.id, snippet.view_url
  end 

  ## VIEW
  desc "view [PROJECT] [SNIPPET_ID]", "view a snippet"
  long_desc <<-D
    View the content of a snippet. Content will be displayed in the default pager or in "less."

    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id. [SNIPPET_ID] must be specified as the id of the snippet.  Use 'gitlab snippets [PROJECT]' command to view the snippets available for a project.

    $ gitlab snippet view namespace/project 6

    $ gitlab snippet view 10 6
  D
  def view(project, snippet)
    snippet = GitlabCli::Util::Snippet.view(project, snippet)    

    pager = ENV['pager'] || 'less'

    unless system("echo %s | %s" % [Shellwords.escape(snippet), pager])
      STDERR.puts "Problem displaying snippet"
      exit 1
    end
  end

  ## EDIT
  desc "edit [PROJECT] [SNIPPET_ID]", "edit a snippet"
  long_desc <<-D
    Edit a snippet. Snippet will open in your default text editor or in "vi." 

    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id. [SNIPPET_ID] must be specified as the id of the snippet.  Use 'gitlab snippets [PROJECT]' command to view the snippets available for a project.

    $ gitlab snippet edit namespace/project 6

    $ gitlab snippet edit 10 6
  D
  def edit(project, snippet)
    snippet_obj = GitlabCli::Util::Snippet.get(project, snippet)
    snippet_code = GitlabCli::Util::Snippet.view(project, snippet)

    editor = ENV['editor'] || 'vi'

    temp_file_path = "/tmp/snippet.%s" % [rand]
    File.open(temp_file_path, 'w') { |file| file.write(snippet_code) }

    system("vi %s" % [temp_file_path])

    snippet_code = File.read(temp_file_path)

    snippet = GitlabCli::Util::Snippet.update(project, snippet_obj, snippet_code)
    printf "Snippet updated.\n URL: %s\n", snippet.view_url
  end

  ## DELETE
  desc "delete [PROJECT] [SNIPPET_ID]", "delete a snippet"
  long_desc <<-D
    Delete a snippet. \n
    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id. [SNIPPET_ID] must be specified as the id of the snippet.  Use 'gitlab snippets [PROJECT]' command to view the snippets available for a project.

    $ gitlab snippet delete namespace/project 6

    $ gitlab snippet delete 10 6
  D
  def delete(project, snippet)
    response = ask "Are you sure you want to delete this snippet? (Yes\\No)"
    exit unless response.downcase == 'yes'

    snippet = GitlabCli::Util::Snippet.delete(project, snippet)

    printf "Successfully deleted the snippet.\n"
  end

  ## INFO
  desc "info [PROJECT] [SNIPPET_ID]", "view detailed info for a snippet"
  long_desc <<-D
    View detailed information about a snippet.\n
    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id. [SNIPPET_ID] must be specified as the id of the snippet.  Use 'gitlab snippets [PROJECT]' command to view the snippets available for a project.
  D
  def info(project, snippet)
    snippet = GitlabCli::Util::Snippet.get(project, snippet)

    printf "Snippet ID: %s\n", snippet.id
    printf "Title: %s\n", snippet.title
    printf "File Name: %s\n", snippet.file_name
    printf "Author: %s <%s>\n", snippet.author.name, snippet.author.email
    printf "Created at: %s\n", Time.parse(snippet.created_at)
    printf "Updated at: %s\n", Time.parse(snippet.updated_at)
    printf "Expires at: %s\n", snippet.expires_at.nil? ? "Never" : Time.parse(snippet.expires_at)
  end

  ## DOWNLOAD
  desc "download|save [PROJECT] [SNIPPET_ID] [FILE]", "download/save a snippet locally"
  long_desc <<-D
    Download/Save the contents of a snippet in a local file\n
    [PROJECT] may be specified as [NAMESPACE]/[PROJECT] or [PROJECT_ID].  Use 'gitlab projects' to see a list of projects with their namespace and id. [SNIPPET_ID] must be specified as the id of the snippet.  Use 'gitlab snippets [PROJECT]' command to view the snippets available for a project.
  D
  def download(project, snippet, file_path)
    snippet = GitlabCli::Util::Snippet.download(project, snippet, file_path)

    puts "Snippet file saved successfully.\n"
  end
end
end
end
