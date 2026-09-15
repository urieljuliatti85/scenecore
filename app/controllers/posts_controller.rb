class PostsController < ApplicationController
  before_action :set_band
  before_action :set_post, only: [ :edit, :update, :destroy, :publish, :unpublish ]

  def new
    @post = @band.posts.new
    authorize @post
  end

  def create
    @post = @band.posts.new(post_params)
    authorize @post

    if @post.save
      redirect_to band_path(@band), notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @post
  end

  def update
    authorize @post

    if @post.update(post_params)
      redirect_to band_path(@band), notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @post

    @post.destroy
    redirect_to band_path(@band), notice: "Post deleted."
  end

  def publish
    authorize @post

    @post.published!
    redirect_to band_path(@band), notice: "Post published."
  end

  def unpublish
    authorize @post

    @post.draft!
    redirect_to band_path(@band), notice: "Post unpublished."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_post
    @post = @band.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body, :visibility, :image)
  end
end
