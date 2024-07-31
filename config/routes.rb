# frozen_string_literal: true

Review::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::Review::Engine, at: "discourse-review-plugin" }
