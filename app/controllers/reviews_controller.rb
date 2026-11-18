# frozen_string_literal: true

class ReviewsController < ApplicationController
  requires_plugin "discourse-review-plugin"

  MAX_NAME_LENGTH = 100

  before_action :ensure_admin, only: %i[index destroy]
  skip_before_action :redirect_to_login_if_required, only: [:create]

  def create
    RateLimiter.new(nil, "review-form-#{request.remote_ip}", 5, 1.minute).performed!

    review_params = params.require(:review).permit(:name, :email, :review_text)
    name = review_params[:name].to_s.squish.truncate(MAX_NAME_LENGTH).presence
    email = review_params[:email].to_s.strip
    review_text = review_params[:review_text].to_s.strip

    raise Discourse::InvalidParameters.new(:email) if !EmailAddressValidator.valid_value?(email)
    raise Discourse::InvalidParameters.new(:review_text) if review_text.blank?

    category = Category.find_by(id: SiteSetting.review_form_category)
    raise Discourse::NotFound if category.nil?

    # Post as the system user so a submitter can never impersonate an existing
    # account; the submitter's email is only kept in the admin-visible store.
    post =
      PostCreator.create!(
        Discourse.system_user,
        title: I18n.t("review.topic_title", name: name || I18n.t("review.anonymous")),
        raw: review_text,
        category: category.id,
        skip_validations: true,
      )

    review_id = SecureRandom.hex(16)
    review = {
      "id" => review_id,
      "name" => name,
      "email" => email,
      "review_text" => review_text,
      "topic_id" => post.topic_id,
    }
    ReviewStore.add_review(review_id, review)

    render json: { review: review.slice("id", "name", "review_text") }
  end

  def index
    render json: { reviews: ReviewStore.get_reviews.values }
  end

  def destroy
    ReviewStore.remove_review(params[:review_id])
    render json: success_json
  end
end
