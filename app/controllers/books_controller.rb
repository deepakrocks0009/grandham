class BooksController < ApplicationController
  load_and_authorize_resource :book, :find_by => :find_by_grandham_id

  respond_to :html, :json

  before_filter :find_book, only: [ :show, :update, :history, :edit ]

  def index
    collection = (current_language && current_language.books) || Book
    @books = collection.paginate(:page => params[:page], :per_page => 10)
    respond_with @books
  end

  def show
    respond_with @book
  end

  def new
    @book = Book.unscoped.new
    @book.authors.build
    @book.publishers.build
    @book.covers.build
    @book.libraries.build
  end

  def create
    @book = Book.unscoped.new(params[:book])
    if @book.save
      if current_user.is_an_admin?
        @book.approve!
        state = 'approved'
        redirect_path = language_book_path(@book.language, @book)
      else
        state = 'open'
        redirect_path = root_path
        flash[:notice] = 'The book you added has been submitted for approval. Thank you!'
      end

      @book.new_items.create user_id: current_user.id, language_id: @book.language.id, state: state
      redirect_to redirect_path
    else
      @book.covers.build
      render "new"
    end
  end

  def update
    respond_to do |format|
      @book.update_attributes params[:book]

      record_edit @book, params[:book]
      format.json { respond_with_bip(@book) }
    end
  end

  def edit
    @book.libraries.build if @book.publishers.empty?
  end

  def history
    @creation = @book.new_items.last
    @edits    = (@book.edits.approved + current_language.edits.where(book_id: @book.id)).sort
  end

  def update_cover
    @book.covers.create image: File.open(params[:book][:covers_attributes]['0'][:image].path)
    redirect_to edit_language_book_path(@book.language, @book)
  end

  private

  def find_book
    @book = Book.find_by_grandham_id(params[:id])
  end
end