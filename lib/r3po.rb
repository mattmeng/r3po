require "r3po/constants"
require 'colorize'

module R3po
  MASTER      = :master
  DEVELOPMENT = :development
  FEATURE     = :feature
  RELEASE     = :release
  PATCH       = :patch

  class App
    attr_accessor :version_path

    def initialize
      @version_path = 'version'
    end

    def self.instance
      return (@@instance ||= new)
    end

    def version( &block )
      if File.exists?( @version_path )
        version = File.read( @version_path )
        unless version =~ /^(\d+)\.(\d+)\.(\d+)/
          print_error( "The version file contained a poorly formed version number." )
          return
        end
        version = $1.to_i, $2.to_i, $3.to_i
      else
        puts %Q{
  #{"Warning:".yellow} Writing out a default version file as I
  couldn't find one.  Please make sure your code uses this file
  to detect its version as I will update it so that we maintain
  a clean repo.

  Follow semantic versioning, as described here:
  http://guides.rubygems.org/patterns/#semantic-versioning

}
        self.version = '0.0.0'
        version = 0, 0, 0
      end
      yield *version if block_given?
      return version
    end

    def version=( value )
      File.write( @version_path, value )
      add( @version_path ) do
        commit( "Updating application version to #{value}." )
      end
    end

    # Command methods

    def run( command, message, &block )
      result = `git #{command} 2>&1`
      unless $?.success?
        print_error( "#{message}\n#{result}" )
        return false
      else
        yield result if block_given?
        return true
      end
    end

    def push( branch, &block )
      run( "push origin #{branch}", "Could not push up the branch #{branch}.", &block )
    end

    def delete_branch( branch, &block )
      run( "branch -D #{branch}", "Could not delete local branch #{branch}." ) do
        push( ":#{branch}", &block )
      end
    end

    def checkout_branch( branch, &block )
      run( "checkout #{branch}", "Could not check out #{branch}.", &block )
    end

    def new_branch( source, branch, &block )
      checkout_branch( source ) do
        run( "checkout -b #{branch}", "Could not start a new branch #{branch}." ) do
          push( branch, &block )
        end
      end
    end

    def current_branch( &block )
      run( "rev-parse --abbrev-ref HEAD", "Could not divine the current branch name." ) do |branch|
        case branch
        when /^#{FEATURE}\/(.*)$/
          branch = [FEATURE, $1]
        when /^#{RELEASE}\/(.*)$/
          branch = [RELEASE, $1]
        when /^#{PATCH}\/(.*)$/
          branch = [PATCH, $1]
        end

        unless branch.kind_of?( Array )
          print_error( "Unknown branch format (#{branch})." )
        else
          yield branch if block_given?
          return branch
        end
      end
    end

    def merge( source, target, &block )
      checkout_branch( target ) do
        run(
          "merge --no-ff -m 'Merging #{source} into #{target}' #{source}",
          "Could not merge #{source} into #{target}. Try to manually merge to see if there are conflicts."
        ) do
          push( target, &block )
        end
      end
    end

    def create_tag( tag, &block )
      checkout_branch( MASTER ) do
        run( "tag #{tag}", "Could not create tag #{tag}.", &block )
      end
    end

    def add( file, &block )
      run( "add #{file}", "Couldn't add file #{file}.", &block )
    end

    def commit( message, &block )
      run( "commit -m \"#{message}\"", "Could not commit changes.", &block )
    end

    # Pretty print methods

    def print_success( operation, message )
      puts "#{operation}: ".green + message
    end

    def print_error( message )
      puts 'ERROR: '.red + message
    end
  end
end

namespace :r3po do
	namespace :feature do
	  desc 'Start a new feature branch.  Requires a feature name.'
	  task :start, :name do |target, args|
	    unless args and args.has_key?( :name )
	      Repo::App.instance.print_error( "Please specify a feature name. (Ex. rake r3po:feature:start[mybranch])" )
	    else
	      branch = "#{Repo::FEATURE}/#{args[:name]}"

	      Repo::App.instance.new_branch( Repo::DEVELOPMENT, branch ) do
	        Repo::App.instance.print_success( 'STARTED FEATURE', branch )
	      end
	    end
	  end

	  desc 'Finish the feature branch you are currently on, merging it back into development.'
	  task :finish do
	    Repo::App.instance.current_branch do |branch|
	      unless branch[0] == Repo::FEATURE
	        Repo::App.instance.print_error( 'This is not a feature branch.' )
	      else
	        branch = branch.join( '/' )
	        print "Has a merge request been cleared for #{branch} #{'[y\n]'.blue}: "
	        response = STDIN.gets.chomp

	        if response == 'y'
	          Repo::App.instance.merge( Repo::DEVELOPMENT, branch ) do # Merge development in first.
	            Repo::App.instance.merge( branch, Repo::DEVELOPMENT ) do # Now merge the branch back into development.
	              Repo::App.instance.delete_branch( branch ) do # Delete the remote and local feature branches.
	                Repo::App.instance.print_success( 'FINISHED FEATURE', branch )
	              end
	            end
	          end
	        end
	      end
	    end
	  end
	end

	namespace :release do
    desc "Start a new release branch, incrementing by minor version (1.x.0)."
    task :minor do
      Repo::App.instance.version do |major, minor, patch|
        version = "#{major}.#{minor + 1}.0"
        branch = "#{Repo::RELEASE}/v#{version}"
        Repo::App.instance.new_branch( Repo::DEVELOPMENT, branch ) do
          Repo::App.instance.version = "#{version}.beta1"
          Repo::App.instance.print_success( 'STARTED MINOR RELEASE', branch )
        end
      end
    end

    desc "Start a new release branch, incrementing by major version (x.0.0)."
    task :major do
      Repo::App.instance.version do |major, minor, patch|
        version = "#{major + 1}.0.0"
        branch = "#{Repo::RELEASE}/v#{version}"
        Repo::App.instance.new_branch( Repo::DEVELOPMENT, branch ) do
          Repo::App.instance.version = "#{version}.beta1"
          Repo::App.instance.print_success( 'STARTED MAJOR RELEASE', branch )
        end
      end
    end

	  desc 'Finish the release branch you are currently on, merging it back into development and master and creating a version tag.'
	  task :finish do
	    Repo::App.instance.current_branch do |branch|
	      unless branch[0] == Repo::RELEASE
	        Repo::App.instance.print_error( 'This is not a release branch.' )
	      else
	        Repo::App.instance.version = branch[1][/\d+\.\d+\.\d+/]
	        tag = branch[1]
	        branch = branch.join( '/' )
	        print "Has a merge request been cleared for #{branch} #{'[y\n]'.blue}: "
	        response = STDIN.gets.chomp

	        if response == 'y'
	          Repo::App.instance.merge( branch, Repo::DEVELOPMENT ) do # Merge the release branch back into development.
	            Repo::App.instance.merge( branch, Repo::MASTER ) do # Merge the release branch into master.
	              Repo::App.instance.create_tag( tag ) do # Create a tag at our merge in master.
	                Repo::App.instance.push( tag ) do # Push up the tag.
	                  Repo::App.instance.delete_branch( branch ) do # Delete the remote and local release branches.
	                    # result = `rake build`
	                    Repo::App.instance.print_success( 'FINISHED RELEASE', branch )
	                  end
	                end
	              end
	            end
	          end
	        end
	      end
	    end
	  end
	end

	namespace :patch do
	  desc "Start a new patch branch, incrementing by patch version (1.0.x)."
	  task :start do
	    Repo::App.instance.version do |major, minor, patch|
	      version = "#{major}.#{minor}.#{patch + 1}"
	      branch = "#{Repo::PATCH}/v#{version}"
	      Repo::App.instance.new_branch( Repo::MASTER, branch ) do
	        Repo::App.instance.version = "#{version}.beta1"
	        Repo::App.instance.print_success( 'STARTED PATCH', branch )
	      end
	    end
	  end

	  desc 'Finish the patch branch you are currently on, merging it back into development and master and creating a version tag.'
	  task :finish do
	    Repo::App.instance.current_branch do |branch|
	      unless branch[0] == Repo::PATCH
	        Repo::App.instance.print_error( 'This is not a patch branch.' )
	      else
	        Repo::App.instance.version = branch[1][/\d+\.\d+\.\d+/]
	        tag = branch[1]
	        branch = branch.join( '/' )
	        print "Has a merge request been cleared for #{branch} #{'[y\n]'.blue}: "
	        response = STDIN.gets.chomp

	        if response == 'y'
	          Repo::App.instance.merge( branch, Repo::DEVELOPMENT ) do # Merge the patch branch back into development.
	            Repo::App.instance.merge( branch, Repo::MASTER ) do # Merge the patch branch into master.
	              Repo::App.instance.create_tag( tag ) do # Create a tag at our merge in master.
	                Repo::App.instance.push( tag ) do # Push up the tag.
	                  Repo::App.instance.delete_branch( branch ) do # Delete the remote and local patch branches.
	                    # result = `rake build`
	                    Repo::App.instance.print_success( 'FINISHED PATCH', branch )
	                  end
	                end
	              end
	            end
	          end
	        end
	      end
	    end
	  end
	end
end
