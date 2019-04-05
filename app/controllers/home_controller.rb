class HomeController < ApplicationController
  require 'rest_client'

  def index
    @repositories = Repository.all
  end

  def get_repositories
    Repository.delete_all

    languages = ['ruby', 'php', 'java', 'python', 'c']

    owner = ['login', 'avatar_url']
    repository = ['name', 'full_name', 'url', 'description', 'language', 'stargazers_count','forks','open_issues','watchers']

    attributes = {}
    Repository.attribute_names.each do |k|
      attributes[k] ||= nil
    end

    languages.each_with_index do |language, index|
      p index
      RestClient.get("https://api.github.com/search/repositories?q=language:#{language}&sort=stars&page=1&per_page=1", headers={}) do |response, request, result, &block|
        ActiveSupport::JSON.decode(response).each do |k, v|
          if k == 'items'
              v.each do |object|
                ActiveSupport::JSON.decode(object.to_json).each do |key, value|
                  if key == 'owner'
                    ActiveSupport::JSON.decode(value.to_json).each do |key_obj, value_obj|
                      attributes["#{key}_#{key_obj}"] = value_obj if owner.include?(key_obj)
                    end
                  else
                    attributes[key] = value if repository.include?(key)
                  end
                end
              end
            end
          end
        end
        Repository.create(attributes)
    end
    redirect_to root_path
  end
end
