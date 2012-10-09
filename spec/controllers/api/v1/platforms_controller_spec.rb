# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'api platform user with reader rights' do
  include_examples "api platform user with show rights"

  it 'should be able to perform index action' do
    get :index, :format => :json
    response.should render_template(:index)
  end

  it 'should be able to perform members action' do
    get :members, :id => @platform.id, :format => :json
    response.should render_template(:members)
  end
end

shared_examples_for 'api platform user with writer rights' do

  context 'api platform user with update rights' do
    before do
      put :update, {:platform => {:description => 'new description'}, :id => @platform.id}, :format => :json
    end

    it 'should be able to perform update action' do
      response.should be_success
    end
    it 'ensures that platform has been updated' do
      @platform.reload
      @platform.description.should == 'new description'
    end
  end

  context 'api platform user with add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {:member_id => member.id, :type => 'User', :id => @platform.id}, :format => :json
    end

    it 'should be able to perform add_member action' do
      response.should be_success
    end
    it 'ensures that new member has been added to platform' do
      @platform.members.should include(member)
    end
  end

  context 'api platform user with remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      delete :remove_member, {:member_id => member.id, :type => 'User', :id => @platform.id}, :format => :json
    end

    it 'should be able to perform update action' do
      response.should be_success
    end
    it 'ensures that member has been removed from platform' do
      @platform.members.should_not include(member)
    end
  end

end

shared_examples_for 'api platform user without writer rights' do

  context 'api platform user without update rights' do
    before do
      put :update, {:platform => {:description => 'new description'}, :id => @platform.id}, :format => :json
    end

    it 'should not be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that platform has not been updated' do
      @platform.reload
      @platform.description.should_not == 'new description'
    end
  end

  context 'api platform user without add_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      put :add_member, {:member_id => member.id, :type => 'User', :id => @platform.id}, :format => :json
    end

    it 'should not be able to perform add_member action' do
      response.should_not be_success
    end
    it 'ensures that new member has not been added to platform' do
      @platform.members.should_not include(member)
    end
  end

  context 'api platform user without remove_member rights' do
    let(:member) { FactoryGirl.create(:user) }
    before do
      @platform.add_member(member)
      delete :remove_member, {:member_id => member.id, :type => 'User', :id => @platform.id}, :format => :json
    end

    it 'should be able to perform update action' do
      response.should_not be_success
    end
    it 'ensures that member has not been removed from platform' do
      @platform.members.should include(member)
    end
  end

end

shared_examples_for 'api platform user with reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api platform user with show rights'
end

shared_examples_for 'api platform user without reader rights for hidden platform' do
  before(:each) do
    @platform.update_column(:visibility, 'hidden')
  end

  it_should_behave_like 'api platform user without show rights'
end

shared_examples_for "api platform user with show rights" do
  it 'should be able to perform show action' do
    get :show, :id => @platform.id, :format => :json
    response.should render_template(:show)
  end

  it 'should be able to perform platforms_for_build action' do
    get :platforms_for_build, :format => :json
    response.should render_template(:index)
  end
end

shared_examples_for "api platform user without show rights" do
  [:show, :members].each do |action|
    it "should not be able to perform #{ action } action" do
      get action, :id => @platform.id, :format => :json
      response.body.should == {"message" => "Access violation to this page!"}.to_json
    end
  end
end

describe Api::V1::PlatformsController do
  before do
    stub_symlink_methods

    @platform = FactoryGirl.create(:platform, :visibility => 'open')
    @personal_platform = FactoryGirl.create(:platform, :platform_type => 'personal')
    @user = FactoryGirl.create(:user)
  end

  context 'for guest' do
    
    it "should not be able to perform index action" do
      get :index, :format => :json
      response.status.should == 401
    end

    [:show, :platforms_for_build].each do |action|
      it "should not be able to perform #{ action } action", :anonymous_access  => false do
        get action, :format => :json
        response.status.should == 401
      end
    end

    it 'should be able to perform members action' do
      get :members, :id => @platform.id, :format => :json
      response.should render_template(:members)
    end

    it_should_behave_like 'api platform user with show rights' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'api platform user without reader rights for hidden platform' if APP_CONFIG['anonymous_access']
    it_should_behave_like 'api platform user without writer rights'
  end

  context 'for global admin' do
    before do
      @admin = FactoryGirl.create(:admin)
      @user = FactoryGirl.create(:user)
      http_login(@admin)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user with writer rights'
  end

  context 'for owner user' do
    before do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      @platform.owner = @user; @platform.save
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user with writer rights'
  end

  context 'for reader user' do
    before do
      @user = FactoryGirl.create(:user)
      http_login(@user)
      @platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
      @personal_platform.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

    context 'perform index action with type param' do
      render_views
      %w(main personal).each do |type|
        it "ensures that filter by type = #{type} returns true result" do
          get :index, :format => :json, :type => "#{type}"
          JSON.parse(response.body)['platforms'].map{ |p| p['platform_type'] }.
            uniq.should == ["#{type}"]
        end
      end
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user with reader rights for hidden platform'
    it_should_behave_like 'api platform user without writer rights'
  end

  context 'for simple user' do
    before do
      @user = FactoryGirl.create(:user)
      http_login(@user)
    end

    it_should_behave_like 'api platform user with reader rights'
    it_should_behave_like 'api platform user without reader rights for hidden platform'
    it_should_behave_like 'api platform user without writer rights'
  end
end
