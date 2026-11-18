import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input, Textarea } from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class ReviewForm extends Component {
  @tracked name = "";
  @tracked email = "";
  @tracked reviewText = "";
  @tracked sending = false;
  @tracked sent = false;

  @action
  async createReview(event) {
    event.preventDefault();
    this.sending = true;

    try {
      await ajax("/reviews", {
        type: "POST",
        data: {
          review: {
            name: this.name,
            email: this.email,
            review_text: this.reviewText,
          },
        },
      });
      this.sent = true;
    } catch (error) {
      popupAjaxError(error);
    } finally {
      this.sending = false;
    }
  }

  <template>
    <form {{on "submit" this.createReview}} class="review" id="review-form">
      <label>
        {{i18n "review.create_review.text_name_label"}}
        <Input @type="text" @value={{this.name}} class="form-control" />
      </label>

      <label>
        {{i18n "review.create_review.text_email_label"}}
        <Input @type="email" @value={{this.email}} required={{true}} />
      </label>

      <label>
        {{i18n "review.create_review.text_review_label"}}
        <Textarea @value={{this.reviewText}} required={{true}} />
      </label>

      {{#if this.sent}}
        <p class="thanks">{{i18n "review.create_review.thanks"}}</p>
      {{else}}
        <button type="submit" class="btn btn-primary" disabled={{this.sending}}>
          {{i18n "review.create_review.submit_label"}}
        </button>
      {{/if}}
    </form>
  </template>
}
