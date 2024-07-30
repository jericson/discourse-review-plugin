# frozen_string_literal: true
class ReviewsController < ApplicationController
  requires_plugin "discourse-review-plugin"

  #  requires_login
  before_action :ensure_admin, only: %i[index destroy]

  skip_before_action :check_xhr,
                     :verify_authenticity_token,
                     :redirect_to_login_if_required,
                     only: [:create]

  def create
    Rails.logger.info "Called ReviewsController#update"

    review_id = params[:review_id]
    review_id = Digest::MD5.hexdigest(Time.now.to_i.to_s + params[:review][:email])
    review = {
      "id" => review_id,
      "name" => params[:review][:name],
      "email" => params[:review][:email],
      "message" => params[:review][:message],
    }

    ReviewStore.add_review(review_id, review)

    @date = Time.now.strftime("%a, %-d %b %Y %H:%M:%S  %z'")
    @time = Time.now.in_time_zone("Eastern Time (US & Canada)").strftime("%m/%d/%Y %H:%M %p")

    @mail =
      "
Date: #{@date}
From: #{review["email"] || "unknown@example.com"}
To: #{SiteSetting.review_form_email}
Subject: Review from #{review["name"]} - #{@time}


Name:  #{review["name"]}
Email: #{review["email"]}

Message:

#{review["message"]}"

    Mail.new(@mail).message_id.presence

    receiver = Email::Receiver.new(@mail)
    receiver.process!

    render json: { review: review }
  end

  def index
    Rails.logger.info "Called ReviewsController#index"
    reviews = ReviewStore.get_reviews()

    render json: { reviews: reviews.values }
  end

  def destroy
    Rails.logger.info "Called ReviewsController#destroy"

    ReviewStore.remove_review(params[:review_id])

    render json: success_json
  end
end
