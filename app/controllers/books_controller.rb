class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  require 'date'
  # GET /books
  # GET /books.json
  def index
    @books = Book.all
  end

  # GET /books/1
  # GET /books/1.json
  def show
    @library = Library.find(Book.find(params[:id]).library_id)
  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # GET /books/1/edit
  def edit
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  def getlibrarybooks
    @library_books = Book.where('library_id = ?', params[:library_id])
    #puts "Librarian #{@librarian.id}"
    #puts "library_books #{@library_books}"
  end

  def showrequests
    @requested_books = []
    @requests = HoldRequest.where(student_id: current_student.id)
    @requests.each do  |request|
      @requested_books << Book.where('id = ?', request.book_id)
    end
  end

  def deleterequest
    @request = HoldRequest.where(id: params[:request_id]).first
    @otherRequests = HoldRequest.where(:book_id => @request.book_id).where('queuenumber > ?' ,@request.queuenumber)
    respond_to do |format|
      if @request.destroy
        @book1 = Book.where('id = ?', @request.book_id).first
        @book1.increment(:quantity)
        @book1.save!
        @otherRequests.each do |otherRequest|
            otherRequest.decrement(:queuenumber)
            otherRequest.save!

        end
        format.html { redirect_to :students, notice: 'Request was successfully destroyed.' }
        format.json { head :no_content }
      else
        format.html { render :new }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  def getstudentbooks
    @student_books = []
    #@library = Library.where('university_id = ?', params[:university_id]).first()
    @libraries = Library.where('university_id = ?', params[:university_id])
    @libraries.each do |lib|
       @student_books << Book.where('library_id = ?',lib.id)
       end  
  end

  def displaysearch
    @student_books = []
    text = params[:search]
    criteria = params[:search_by]
    @searched_books = Array.new
    
    @libraries = Library.where('university_id = ?', current_student.university_id)
      if criteria == 'title'
        @libraries.each do |lib|
        @searched_books.push Book.where('title LIKE ?',"%#{text}%").where('library_id  = ?', lib.id)
      end
      elsif criteria == 'author'
        @libraries.each do |lib|
        @searched_books.push Book.where('author LIKE ?',"%#{text}%").where('library_id  = ?', lib.id)
      end
      elsif criteria == 'subject'
        @libraries.each do |lib|
        @searched_books.push Book.where('subject LIKE ?',"%#{text}%").where('library_id  = ?', lib.id)
      end
      elsif criteria == 'publication date'
        @libraries.each do |lib|
        @searched_books.push Book.where('published LIKE ?',"%#{text}%").where('library_id  = ?', lib.id)
      end
    end
  end

  def search
  end


  def checkout
    @student = Student.find(params[:student_id])
    @book = Book.find(params[:book_id])
    @holdRequest = HoldRequest.new
    quantity = @book.quantity
    if BookIssueHistory.where(:student_id => @student.id, :book_id => @book.id,:return_date  => nil).first.nil?
      if quantity > 0
        issue_date = Date.today
        overdue_date = issue_date + (@student.max_days_borrowed).days
        @book_issue_history = BookIssueHistory.new
        @book_issue_history.book_id = @book.id
        @book_issue_history.library_id = @book.library_id
        @book_issue_history.student_id = @student.id
        @book_issue_history.issue_date = issue_date
        @book_issue_history.overdue_date = overdue_date
        @book.decrement(:quantity)
        @book.save!
        respond_to do |format|
          if @book_issue_history.save
            format.html { redirect_to :students, notice: 'Book successfully checked out.' }
            format.json { render :show, status: :created, location: @book_issue_history }
          else
            format.html { render :new }
            format.json { render json: @book_issue_history.errors, status: :unprocessable_entity }
          end
        end
      else
        if HoldRequest.where(student_id: @student.id, book_id: @book.id).first
          redirect_to :students, notice: 'No books available, your hold request has already been placed'
        else
          @holdRequest.book_id = @book.id
          @holdRequest.student_id = @student.id
          @book.decrement(:quantity)
          @book.save!
          @holdRequest.queuenumber = (@book.quantity).abs

          respond_to do |format|
            if @holdRequest.save
              format.html { redirect_to :students, notice: "Hold request has been placed, your number in queue is #{@holdRequest.queuenumber}" }
              format.json { render :show, status: :created, location: @holdRequest }
            else
              format.html { render :new }
              format.json { render json: @holdRequest.errors, status: :unprocessable_entity }
            end
           end
        end
      end
    else
      redirect_to :students, notice: 'Book already checked out.'
      end
  end

  def return
    @student = Student.find(params[:student_id])
    @book = Book.find(params[:book_id])
    #quantity = @book.quantity
    unless BookIssueHistory.where(:student_id => @student.id, :book_id => @book.id,:return_date  => nil).first.nil?
        @book_issue_history = BookIssueHistory.where(:student_id => @student.id, :book_id => @book.id,:return_date  => nil).first
        @book_issue_history.return_date = Date.today
        @book.increment(:quantity)
        @book.save!
        respond_to do |format|
          if @book_issue_history.save
            format.html { redirect_to :students, notice: 'Book successfully returned.' }
            format.json { render :show, status: :created, location: @book_issue_history }
          else
            format.html { render :new }
            format.json { render json: @book_issue_history.errors, status: :unprocessable_entity }
          end
        end
    else
      redirect_to :students, notice: 'Book not checked out.'
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:title,:isbn,:author,:language,:published,:edition,:cover_image,:subject,
                                   :library_id,:summary,:quantity,:special_collection)
    end
end
