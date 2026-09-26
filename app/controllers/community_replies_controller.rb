class CommunityRepliesController < ApplicationController
  before_action :set_band_and_topic
  before_action :set_reply, only: :destroy

  def create
    @reply = @topic.community_replies.new(reply_params.merge(user: current_user))
    authorize @reply

    if @reply.save
      redirect_to community_topic_path(@band.slug, @topic), notice: "Reply posted."
    else
      redirect_to community_topic_path(@band.slug, @topic), alert: @reply.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @reply
    log_platform_moderation(@reply)
    @reply.destroy!
    redirect_to community_topic_path(@band.slug, @topic), notice: "Reply deleted."
  end

  private

  def set_band_and_topic
    @band = Band.approved.find_by!(slug: params[:slug])
    @topic = @band.community_topics.find(params[:topic_id])
  end

  def set_reply
    @reply = @topic.community_replies.find(params[:id])
  end

  def reply_params
    params.require(:community_reply).permit(:body)
  end

  def log_platform_moderation(subject)
    return unless current_user.platform_admin?
    return if subject.user_id == current_user.id
    return if @band.band_memberships.administrator.exists?(user_id: current_user.id)

    AdminActionLog.create!(actor: current_user, action: "moderate_delete_community_reply", subject: subject)
  end
end
