[![Gem Version](https://badge.fury.io/rb/r3po.svg)](http://badge.fury.io/rb/r3po)

# r3po

A gem that provides rake tasks to enforce standard semantic versioning and repo cleanliness.  See the following article for an overview of the repository strategy used: http://nvie.com/posts/a-successful-git-branching-model/

![Repo Strategy](http://nvie.com/img/git-model@2x.png "Repo Strategy")

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'r3po'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install r3po

## Usage

You must start with at least a `master` and `development` branch.  Master should be the branch that, at every commit, contains working and stable code as far as you can test.  Development is the dirty branch, it could be work, it could not be; we don't care.  It's where most bugs and all feature get dumped.  Master and development should NEVER be merged into each other directly.

R3po will namespace all your branches depending on what type of branch it is:

Feature Branch: `feature/branch_name`<br />
Release Branch: `release/vX.Y.Z`<br />
Patch Branch:   `patch/vX.Y.Z`<br />

The version your code is on should be stored in a file called `version` on the same level as your rakefile. It should contain the semantic version of your code.  R3po will automatically update this and use this file to create tags and branches for you.

### Feature Branches

Feature branches allow you to work on particular features without impacting other features or bugs.  To create a feature branch, from your repo issue:

```bash
rake r3po:feature:start[my_new_branch]
```

This will automatically branch a new feature from off of development, naming it `feature/my_new_branch`.

Feature branches should be regularly updated from trunk, but should NEVER be merged back into trunk until the feature is finished.  To accomplish this task, issue the following while the feature branch you want to finish is checked out:

```bash
rake r3po:feature:finish
```

This will merge development into your branch to make sure it is up to date.  Then it will merge your feature branch back into development.  Finally it will delete both your local and the remote copy of the feature branch and push all changes up to origin.

### Release Branches

Release branches give you a place to work on final bugs before you want to make a major or minor release.  Using the `version` file mentioned above, it will auto increment your version depending on which type of release it is.  To create a minor version release (Ex. 1.8.1 going to 1.9.0), issue:

```bash
rake r3po:release:minor
```

To create a major release (Ex. 1.8.1 going to 2.0.0), issue:

```bash
rake r3po:release:major
```

Both commands will branch a new release off of development and increment the version in the `version` file and commit that change.  The new branch will be named `release/vX.Y.Z` with 'X.Y.Z' being the new version number.

Release branches should only contain bug fixes on features that have been included in this release or on previously available functionality.  Development should NEVER be merged back into a release branch.  But periodic merges of the release back into the development branch are OK.  To finish the release branch:

```bash
rake r3po:release:finish
```

This will update the version number again, just in case you made beta branch numbers.  It will then merge the release branch into development, and then into master.  It will create a new tag on master for the version, and push all changes up to origin.  It will also delete the local and remote copies of the release branch.

### Patch Branches

Patch branches are for fixes found to exist in master that need immediate attention and can't wait for a major or minor release. Using the `version` file, it will auto increment your version by the patch number (Ex. 1.8.1 going to 1.8.2).  To start a patch, issue:

```bash
rake r3po:patch:start
```

This will branch off a new patch branch from master, incrementing the version appropriately and checking in that change.  The patch branch will be named `patch/vX.Y.Z` with the 'X.Y.Z' being the new version number. Patch branches should not be merged anywhere until they are complete.  Make bug fixes as needed and then finish the patch:

```bash
rake r3po:patch:finish
```

This will update the version to the official number, merge the patch into development and then into master.  It will then create the appropriate version tag on master and delete the local and remote copies of the patch branch.

## Contributing

1. Fork it ( https://github.com/mattmeng/r3po/fork )
2. Add Repo to your gemspec and rakefile (`require 'r3po'`)
3. Create your feature branch (`rake r3po:feature:start[my-new-feature]`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
