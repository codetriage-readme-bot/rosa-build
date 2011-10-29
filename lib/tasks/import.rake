namespace :import do
  desc "Load projects"
  task :projects => :environment do
    open('http://dl.dropbox.com/u/984976/PackageList.txt').readlines.each do |name|
      name.chomp!
      print "Import #{name}..."
      owner = User.find(2) # vsharshov@gmail.com
      # owner = Group.find(1) # Core Team
      puts Project.create(:name => name, :unixname => name) {|p| p.owner = owner} ? "Ok!" : "Fail!"
      sleep 1
    end
    puts 'DONE'
  end
end
