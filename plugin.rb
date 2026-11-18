# frozen_string_literal: true

# name: discourse-review-plugin
# about: Allow anyone to post a review
# meta_topic_id: TODO
# version: 0.0.1
# authors: Jon Ericson
# url: https://github.com/jericson/discourse-review-plugin
# required_version: 2.7.0

enabled_site_setting :review_form_enabled

register_asset "stylesheets/review.scss"

module ::Review
  PLUGIN_NAME = "discourse-review-plugin"
end

require_relative "lib/review/engine"
require_relative "lib/review/review_store"

after_initialize do
  require_relative "app/controllers/reviews_controller"

  Discourse::Application.routes.append do
    get "/reviews" => "reviews#index"
    post "/reviews" => "reviews#create"
    delete "/reviews/:review_id" => "reviews#destroy"
  end
end
