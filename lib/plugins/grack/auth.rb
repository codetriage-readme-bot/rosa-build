module Grack
  class Auth < Base
    def initialize(app)
      @app = app
    end

    # TODO tests!!!
    def call(env)
      super
      if git?
        return render_not_found if project.blank?

        return ::Rack::Auth::Basic.new(@app) do |u, p|
          user                = User.auth_by_token_or_login_pass(u, p) &&
          ability             = ::Ability.new(user) && ability.can?(action, project) &&
          ENV['GL_ID']        = "user-#{user.id}" &&
          ENV['GL_REPO_PATH'] = project.path
        end.call(env) unless project.public? && read? # need auth
      end
      @app.call(env) # next app in stack
    end
  end
end
