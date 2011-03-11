Rosa::Application.routes.draw do
  devise_for :users

  resources :platforms do
    resources :repositories do
      resources :projects do
        resource :repo, :controller => "git/repositories", :only => [:show]
      end
    end
  end

  resources :users

  # Tree
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/tree/:treeish(/*path)', :controller => "git/trees", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :tree

  # Commits
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commits/:treeish(/*path)', :controller => "git/commits", :action => :index, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :commits
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/:id(.:format)', :controller => "git/commits", :action => :show, :defaults => { :format => :html }, :as => :commit

  # Blobs
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/blob/:treeish/*path', :controller => "git/blobs", :action => :show, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blob
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/blob/:commit_hash/*path', :controller => "git/blobs", :action => :show, :platform_name => /[0-9a-zA-Z_.\-]*/, :project_name => /[0-9a-zA-Z_.\-]*/, :as => :blob_commit

  # Blame
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/blame/:treeish/*path', :controller => "git/blobs", :action => :blame, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :blame
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/blame/:commit_hash/*path', :controller => "git/blobs", :action => :blame, :as => :blame_commit

  # Raw
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/raw/:treeish/*path', :controller => "git/blobs", :action => :raw, :treeish => /[0-9a-zA-Z_.\-]*/, :defaults => { :treeish => :master }, :as => :raw
  match 'platforms/:platform_id/repositories/:repository_id/projects/:project_id/git/commit/raw/:commit_hash/*path', :controller => "git/blobs", :action => :raw, :as => :raw_commit

  root :to => "platforms#index"
end
