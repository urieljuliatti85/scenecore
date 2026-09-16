class CommentsController < ApplicationController
  before_action :set_post

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create
    @comment = @post.comments.new(comment_params.merge(user: current_user))
    authorize @comment

    if @comment.save
      redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), notice: "Comment posted."
    else
      redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), alert: @comment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    authorize @comment

    @comment.destroy
    redirect_to public_band_path(params[:slug], anchor: "post-#{@post.id}"), notice: "Comment deleted."
  end

  private

  def set_post
    band = Band.approved.find_by!(slug: params[:slug])
    @post = band.posts.published.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
