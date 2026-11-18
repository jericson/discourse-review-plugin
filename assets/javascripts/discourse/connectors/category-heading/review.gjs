import Component from "@glimmer/component";
import { service } from "@ember/service";
import ReviewForm from "../../components/review-form";

export default class ReviewConnector extends Component {
  @service siteSettings;

  get isReviewCategory() {
    const categoryId = this.siteSettings.review_form_category;
    return (
      categoryId && String(this.args.outletArgs.category?.id) === categoryId
    );
  }

  <template>
    {{#if this.isReviewCategory}}
      <div class="category-heading-outlet review">
        {{this.siteSettings.review_form_intro}}
        <br />
        <ReviewForm />
        <hr />
      </div>
    {{/if}}
  </template>
}
