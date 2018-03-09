namespace :documentation do
  desc "Load a set of initial guides"
  task :install_guides => :environment do
    require File.expand_path('../../../db/seeds', __FILE__)
  end

  task :backup_extract => :environment do
    require File.expand_path('../../../db/backup', __FILE__)

    backup_service = Documentation::Backup.new
    backup_service.extract!
  end

  task :backup_insert => :environment do
    require File.expand_path('../../../db/backup', __FILE__)

    backup_service = Documentation::Backup.new
    backup_service.insert!
  end
end
