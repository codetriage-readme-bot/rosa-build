# -*- encoding : utf-8 -*-
require 'spec_helper'
require "cancan/matchers"

def admin_create
	@admin = FactoryGirl.create(:admin)
  @ability = Ability.new(@admin)
end

def user_create
	@user = FactoryGirl.create(:user)
  @ability = Ability.new(@user)
end

def guest_create
  @ability = Ability.new(User.new)
end

describe CanCan do

	let(:personal_platform) { FactoryGirl.create(:platform, :platform_type => 'personal') }
	let(:personal_repository) { FactoryGirl.create(:personal_repository) }
	let(:open_platform) { FactoryGirl.create(:platform, :visibility => 'open') }
	let(:hidden_platform) { FactoryGirl.create(:platform, :visibility => 'hidden') }
  let(:register_request) { FactoryGirl.create(:register_request) }

  before(:each) do
    stub_symlink_methods
  end

	context 'Site admin' do
		before(:each) do
			admin_create
		end
		
		it 'should manage all' do
			#(@ability.can? :manage, :all).should be_true
			@ability.should be_able_to(:manage, :all)
		end

		it 'should not be able to destroy personal platforms' do
			@ability.should_not be_able_to(:destroy, personal_platform)
		end

		it 'should not be able to destroy personal repositories' do
			@ability.should_not be_able_to(:destroy, personal_repository)
		end
	end

	context 'Site guest' do
		before(:each) do
			guest_create
		end

    it 'should not be able to read open platform' do
    	@ability.should_not be_able_to(:read, open_platform)
    end

    it 'should not be able to read hidden platform' do
    	@ability.should_not be_able_to(:read, hidden_platform)
    end

		[:publish_build, :status_build, :pre_build, :post_build, :circle_build, :new_bbdt].each do |action|
			it "should be able to #{ action } build list" do
				@ability.should be_able_to(action, BuildList)
			end
		end

    it 'should not be able to update register request' do
      @ability.should_not be_able_to(:update, register_request)
    end

    it 'should not be able to list register requests' do
      @ability.should_not be_able_to(:read, register_request)
    end

    it 'should not be able to destroy register requests' do
      @ability.should_not be_able_to(:destroy, register_request)
    end

		pending 'should be able to register new user' do # while self registration is closed
			@ability.should be_able_to(:create, User)
		end
	end

  context 'Site user' do
    before(:each) do
      user_create
    end

    [Platform, Repository].each do |model_name|
      it "should not be able to read #{model_name}" do
        @ability.should be_able_to(:read, model_name)
      end
    end
    
    it "shoud be able to show user profile" do
      @ability.should be_able_to(:show, User)
    end

    it "shoud be able to read another user object" do
      admin_create
      @ability.should be_able_to(:read, @admin)
    end

    pending "shoud be able to read index AutoBuildList" do
      @ability.should be_able_to(:index, AutoBuildList)
    end

    it "shoud be able to read open projects" do
      @project = FactoryGirl.create(:project, :visibility => 'open')
      @ability.should be_able_to(:read, @project)
    end

    it "shoud be able to create project" do
      @ability.should be_able_to(:create, Project)
    end

    it "should not be able to manage register requests" do
      @ability.should_not be_able_to(:manage, RegisterRequest)
    end

    context "private users relations" do
      before(:each) do
        @private_user = FactoryGirl.create(:private_user)
        
        @private_user.platform.owner = @user
        @private_user.platform.save
      end

      [:read, :create].each do |action|
        it "should be able to #{ action } PrivateUser" do
          @ability.should be_able_to(action, @private_user) 
        end
      end
    end

    context 'as project collaborator' do
      before(:each) do
        @project = FactoryGirl.create(:project)
        @issue = FactoryGirl.create(:issue, :project_id => @project.id)
      end

      context 'with read rights' do
        before(:each) do
          @project.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'reader')
        end

        it 'should be able to read project' do
          @ability.should be_able_to(:read, @project)
        end

        it 'should be able to read open platform' do
          @ability.should be_able_to(:read, open_platform)
        end

        it 'should be able to read issue' do
          @ability.should be_able_to(:read, @issue)
        end
      end

      context 'with writer rights' do
        before(:each) do
          @project.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'writer')
        end

        [:read, :create, :new].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end

        [:new, :create].each do |action|
          it "should be able to #{action} build_list" do
            @build_list = FactoryGirl.create(:build_list, :project => @project)
            @ability.should be_able_to(action, @build_list)
          end
        end
      end

      context 'with admin rights' do
        before(:each) do
          @project.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'admin')
        end

        [:read, :update].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end

        [:new, :create].each do |action|
          it "should be able to #{action} build_list" do
            @build_list = FactoryGirl.create(:build_list, :project => @project)
            @ability.should be_able_to(action, @build_list)
          end
        end

        it "should be able to manage collaborators of project" do
          @ability.should be_able_to(:manage_collaborators, @project)
        end

        [:read, :create, :new, :update, :edit].each do |action|
          it "should be able to #{ action } issue" do
            @ability.should be_able_to(action, @issue)
          end
        end
      end

      context 'with owner rights' do
        before(:each) do
          @project.owner = @user
          @project.save
          
          @project.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'admin')
          @issue.project.reload
        end

        [:read, :update, :destroy].each do |action|
          it "should be able to #{ action } project" do
            @ability.should be_able_to(action, @project)
          end
        end

        [:new, :create].each do |action|
          it "should be able to #{action} build_list" do
            @build_list = FactoryGirl.create(:build_list, :project => @project)
            @ability.should be_able_to(action, @build_list)
          end
        end

        [:read, :update, :edit].each do |action|
          it "should be able to #{ action } issue" do
            @ability.should be_able_to(action, @issue)
          end
        end
      end

    end

    context 'platform relations' do
      before(:each) do
        @platform = FactoryGirl.create(:platform)
      end

      context 'with owner rights' do
        before(:each) do
          @platform.owner = @user
          @platform.save
        end

        [:read, :update, :destroy].each do |action|
          it "should be able to #{action} platform" do
            @ability.should be_able_to(action, @platform)
          end
        end
      end

      context 'with read rights' do
        before(:each) do
          @platform.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'reader')
        end

        it "should be able to read platform" do
          @ability.should be_able_to(:read, @platform)
        end
      end
    end

    context 'repository relations' do
      before(:each) do
        @repository = FactoryGirl.create(:repository)
      end

      context 'with owner rights' do
        before(:each) do
          @repository.platform.owner = @user; @repository.platform.save
        end

        [:read, :create, :update, :destroy, :add_project, :remove_project, :change_visibility, :settings].each do |action|
          it "should be able to #{action} repository" do
            @ability.should be_able_to(action, @repository)
          end
        end
      end

      context 'with read rights' do
        before(:each) do
          @repository.platform.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'reader')
        end

        it "should be able to read repository" do
          @ability.should be_able_to(:read, @repository)
        end
      end
    end

    context 'build list relations' do
      before(:each) do
        @project = FactoryGirl.create(:project)
        @project.relations.create!(:actor_id => @user.id, :actor_type => 'User', :role => 'writer')
        @build_list = FactoryGirl.create(:build_list, :project => @project)
      end

      it 'should be able to publish build list with SUCCESS status' do
        @build_list.status = BuildServer::SUCCESS
        @ability.should be_able_to(:publish, @build_list)
      end

      it 'should not be able to publish build list with another status' do
        @build_list.status = BuildServer::BUILD_ERROR
        @ability.should_not be_able_to(:publish, @build_list)
      end
    end
  end


end
