class ReportsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create_for_post
    band = Band.approved.find_by!(slug: params[:slug])
    post = band.posts.published.find(params[:post_id])

    create_report(post, public_band_path(band.slug, anchor: "post-#{post.id}"))
  end

  def create_for_comment
    band = Band.approved.find_by!(slug: params[:slug])
    post = band.posts.published.find(params[:post_id])
    comment = post.comments.find(params[:comment_id])

    create_report(comment, public_band_path(band.slug, anchor: "post-#{post.id}"))
  end

  def create_for_community_topic
    band = Band.approved.find_by!(slug: params[:slug])
    topic = band.community_topics.find(params[:topic_id])

    create_report(topic, community_topic_path(band.slug, topic))
  end

  def create_for_community_reply
    band = Band.approved.find_by!(slug: params[:slug])
    topic = band.community_topics.find(params[:topic_id])
    reply = topic.community_replies.find(params[:reply_id])

    create_report(reply, community_topic_path(band.slug, topic))
  end

  private

  def create_report(reportable, redirect_path)
    report = Report.new(reportable: reportable, reporter: current_user, reason: report_params[:reason])
    authorize report, :create?

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
