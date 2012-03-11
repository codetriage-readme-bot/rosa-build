# -*- encoding : utf-8 -*-
module UsersHelper

  def avatar_url_by_email(email, size = :small)
    avatar_url(User.where(:email => email).first, size)
  end

  def avatar_url(user, size = :small)
    if user.try('avatar?')
      user.avatar.url(size)
    else
      gravatar_url(user.email, user.avatar.styles[size].geometry.split('x').first)
    end
  end

  def gravatar_url(email, size = 30)
    "https://secure.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=#{size}&r=pg"
  end
end
