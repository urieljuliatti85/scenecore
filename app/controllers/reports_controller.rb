class ReportsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create_for_post
    band = Band.approved.find_by!(slug: params[:slug])
    post = band.posts.published.find(params[:post_id])

    create_report(post)
  end

  def create_for_comment
    band = Band.approved.find_by!(slug: params[:slug])
    post = band.posts.published.find(params[:post_id])
    comment = post.comments.find(params[:comment_id])

    create_report(comment)
  end

  private

  def create_report(reportable)
    report = Report.new(reportable: reportable, reporter: current_user, reason: report_params[:reason])
    authorize report, :create?

    redirect_path = public_band_path(params[:slug], anchor: "post-#{reportable.is_a?(Comment) ? reportable.post_id : reportable.id}")

    if report.save
      redirect_to redirect_path, notice: "Thanks — this has been reported to SceneCore."
    else
      redirect_to redirect_path, alert: report.errors.full_messages.to_sentence
    end
  end

  def report_params
    params.require(:report).permit(:reason)
  end
end
