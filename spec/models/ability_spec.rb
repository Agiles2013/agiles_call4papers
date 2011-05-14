require 'spec/spec_helper'

describe Ability do
  before(:each) do
    @user = Factory(:user)
  end
  
  shared_examples_for "all users" do
    it "can read all" do
      @ability.should be_can(:read, :all)
    end
    
    it "can login/logout" do
      @ability.should be_can(:create, UserSession)
      @ability.should be_can(:destroy, UserSession)
    end
    
    it "can create a new account" do
      @ability.should be_can(:create, User)
    end
    
    it "can update their own account" do
      @ability.should be_can(:update, @user)
      @ability.should be_cannot(:update, User.new)
    end

    it "can create comments" do
      @ability.should be_can(:create, Comment)
    end
    
    it "can edit their comments" do
      comment = Comment.new
      @ability.should be_cannot(:edit, comment)
      comment.user = @user
      @ability.should be_can(:edit, comment)
    end
    
    it "can update their comments" do
      comment = Comment.new
      @ability.should be_cannot(:update, comment)
      comment.user = @user
      @ability.should be_can(:update, comment)
    end

    it "can destroy their comments" do
      comment = Comment.new
      @ability.should be_cannot(:destroy, comment)
      comment.user = @user
      @ability.should be_can(:destroy, comment)
    end
    
    it "can read votes" do
      vote = Vote.new
      @ability.should be_can(:read, vote)
    end
    
    it "cannot update votes" do
      @ability.should be_cannot(:update, Vote)
      vote = Vote.new
      @ability.should be_cannot(:update, vote)
    end
    
    describe "can vote if:" do
      before(:each) do
        Time.zone.stubs(:now).returns(Time.zone.local(2010, 1, 1))
      end
      
      it "- haven't voted yet" do
        @ability.should be_can(:create, Vote)
        Factory(:vote, :user => @user)
        @ability.should be_cannot(:create, Vote)
      end
      
      it "- before deadline of 7/3/2010" do
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 7, 23, 59, 59))
        @ability.should be_can(:create, Vote)
      end
      
      it "- after deadline can't vote" do
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 8, 0, 0, 0))
        @ability.should be_cannot(:create, Vote)
      end
    end

    describe "can change vote if:" do
      before(:each) do
        Time.zone.stubs(:now).returns(Time.zone.local(2010, 1, 1))
        @vote = Factory(:vote, :user => @user)
      end
      
      it "- has already voted" do
        @ability.should be_can(:update, @vote)
      end

      it "- vote belongs to user" do
        another_vote = Factory(:vote)
        @ability.should be_can(:update, @vote)
        @ability.should be_cannot(:update, another_vote)
      end
      
      it "- before deadline of 7/3/2010" do
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 7, 23, 59, 59))
        @ability.should be_can(:update, @vote)
      end
      
      it "- after deadline can't vote" do
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 8, 0, 0, 0))
        @ability.should be_cannot(:update, @vote)
      end
    end
    
    it "can new vote after voting" do
      @ability.should be_can(:new, Vote)
      Factory(:vote, :user => @user)
      @ability.should be_can(:new, Vote)
    end
  end

  context "- all users (guests)" do
    before(:each) do
      @ability = Ability.new(@user)
    end

    it_should_behave_like "all users"

    it "cannot manage reviewer" do
      @ability.should be_cannot(:manage, Reviewer)
    end
    
    it "cannot read organizers" do
      @ability.should be_cannot(:read, Organizer)
    end
    
    it "cannot read reviews" do
      @ability.should be_cannot(:read, Review)
    end
    
    it "cannot read reviews listing" do
      @ability.should be_cannot(:read, 'reviews_listing')
    end
    
    it "cannot read sessions to organize" do
      @ability.should be_cannot(:read, 'organizer_sessions')
    end

    it "cannot read sessions to review" do
      @ability.should be_cannot(:read, 'reviewer_sessions')
    end

    describe "can update reviewer if:" do
      before(:each) do
        @reviewer = Factory(:reviewer, :user => @user)
        @reviewer.invite
      end
      
      it "- user is the same" do
        @ability.should be_can(:update, @reviewer)
        @reviewer.user = nil
        @ability.should be_cannot(:update, @reviewer)
      end
      
      it "- reviewer is in invited state" do
        @ability.should be_can(:update, @reviewer)
        @reviewer.preferences.build(:accepted => true, :track_id => 1, :audience_level_id => 1)
        @reviewer.accept
        @ability.should be_cannot(:update, @reviewer)
      end
    end
  end
  
  context "- admin" do
    before(:each) do
      @user.add_role "admin"
      @ability = Ability.new(@user)
    end

    it "can manage all" do
      @ability.should be_can(:manage, :all)
    end
  end

  context "- author" do
    before(:each) do
      @user.add_role "author"
      @ability = Ability.new(@user)
    end

    it_should_behave_like "all users"

    it "cannot manage reviewer" do
      @ability.should be_cannot(:manage, Reviewer)
    end
    
    it "cannot read organizers" do
      @ability.should be_cannot(:read, Organizer)
    end
    
    it "cannot read reviews" do
      @ability.should be_cannot(:read, Review)
    end
    
    context "index reviews of" do
      before(:each) do
        @decision = Factory(:review_decision, :published => true)
        @session = @decision.session
      end
      
      it "his sessions as first author is allowed" do
        @ability.should be_cannot(:index, Review) # no params
        @ability.should be_cannot(:index, Review, @session)
        
        @ability = Ability.new(@user, {:session_id => @session.to_param})
        @ability.should be_cannot(:index, Review) # session id provided
        @ability.should be_cannot(:index, Review, @session)
        @session.reload.update_attribute(:author_id, @user.id)
        @ability.should be_can(:index, Review) # session id provided
        @ability.should be_can(:index, Review, @session)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:index, Review) # session id nil
        @ability.should be_can(:index, Review, @session)
      end

      it "his sessions as second author is allowed" do
        @ability.should be_cannot(:index, Review) # no params
        @ability.should be_cannot(:index, Review, @session)
        
        @ability = Ability.new(@user, {:session_id => @session.to_param})
        @ability.should be_cannot(:index, Review) # session id provided
        @ability.should be_cannot(:index, Review, @session)
        @session.reload.update_attribute(:second_author_id, @user.id)
        @ability.should be_can(:index, Review) # session id provided
        @ability.should be_can(:index, Review, @session)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:index, Review) # session id nil
        @ability.should be_can(:index, Review, @session)
      end
      
      it "his sessions if review has been published" do
        @session.author = @user
        @ability.should be_can(:index, Review, @session)
        @session.review_decision.published = false
        @ability.should be_cannot(:index, Review, @session)
      end
      
      it "other people's sessions is forbidden" do
        session = Factory(:session)
        @ability.should be_cannot(:index, Review) # no params
        @ability.should be_cannot(:index, Review, session)
        
        @ability = Ability.new(@user, :session_id => session.to_param)
        @ability.should be_cannot(:index, Review) # session id provided
        @ability.should be_cannot(:index, Review, session)  

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:index, Review) # session id nil
        @ability.should be_cannot(:index, Review, session)
      end
    end
    
    it "cannot read reviews listing" do
      @ability.should be_cannot(:read, 'reviews_listing')
    end
    
    it "cannot read sessions to organize" do
      @ability.should be_cannot(:read, 'organizer_sessions')
    end

    it "cannot read sessions to review" do
      @ability.should be_cannot(:read, 'reviewer_sessions')
    end
    
    describe "can create sessions if:" do
      before(:each) do
        Time.zone.stubs(:now).returns(Time.zone.local(2010, 1, 1))
      end
      
      it "- before deadline of 29/5/2010" do
        Time.zone.expects(:now).returns(Time.zone.local(2011, 5, 29, 23, 59, 59))
        @ability.should be_can(:create, Session)
      end
      
      it "- after deadline 29/5/2010 author can't update" do
        Time.zone.expects(:now).returns(Time.zone.local(2011, 5, 30, 0, 0, 0))
        @ability.should be_cannot(:create, Session)
      end
    end
    
    describe "can update session if:" do
      before(:each) do
        @session = Factory(:session)
        Time.zone.stubs(:now).returns(Time.zone.local(2010, 1, 1))
      end
      
      it "- user is first author" do
        @ability.should be_cannot(:update, @session)
        @session.author = @user
        @ability.should be_can(:update, @session)
      end
      
      it "- user is second author" do
        @ability.should be_cannot(:update, @session)
        @session.second_author = @user
        @ability.should be_can(:update, @session)
      end
      
      it "- before deadline of 7/3/2010" do
        @session.author = @user
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 7, 23, 59, 59))
        @ability.should be_can(:update, @session)
      end
      
      it "- after deadline author can't update" do
        @session.author = @user
        Time.zone.expects(:now).returns(Time.zone.local(2010, 3, 8, 0, 0, 0))
        @ability.should be_cannot(:update, @session)
      end
    end
  end

  context "- organizer" do
    before(:each) do
      @user.add_role "organizer"
      @ability = Ability.new(@user)
    end

    it_should_behave_like "all users"
    
    it "can manage reviewer" do
      @ability.should be_can(:manage, Reviewer)
    end
    
    it "cannot read organizers" do
      @ability.should be_cannot(:read, Organizer)
    end

    it "can show reviews" do
      @ability.should be_can(:show, Review)
    end
    
    it "cannot read reviews listing" do
      @ability.should be_cannot(:read, 'reviews_listing')
    end
    
    it "can read sessions to organize" do
      @ability.should be_can(:read, 'organizer_sessions')
    end

    it "cannot read sessions to review" do
      @ability.should be_cannot(:read, 'reviewer_sessions')
    end
    
    context "organizer index reviews of" do
      before(:each) do
        @session = Factory(:session)
      end
      
      it "session on organizer's track is allowed" do
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_cannot(:organizer, Review) # no params
        
        @ability = Ability.new(@user, :session_id => @session.to_param)
        @ability.should be_can(:organizer, Review) # session id provided

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:organizer, Review) # session id nil
      end
      
      it "session outside of organizer's track is forbidden" do
        @ability.should be_cannot(:organizer, Review) # no params
        
        @ability = Ability.new(@user, :session_id => @session.to_param)
        @ability.should be_cannot(:organizer, Review) # session id provided

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:organizer, Review) # session id nil
      end
    end
    
    context "can cancel session if:" do
      before(:each) do
        @session = Factory(:session)
      end
      
      it "- session on organizer's track" do
        @ability.should be_cannot(:cancel, @session)
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:cancel, @session)
      end
      
      it "- session is not already cancelled" do
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:cancel, @session)
        @session.cancel
        @ability.should be_cannot(:cancel, @session)
      end
    end

    context "can create review decision if:" do
      before(:each) do
        @session = Factory(:session)
        @session.reviewing
      end
      
      it "- session on organizer's track" do
        @ability.should be_cannot(:create, ReviewDecision, @session)
        @ability.should be_cannot(:create, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:create, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:create, ReviewDecision)
        
        Factory(:organizer, :track => @session.track, :user => @user)

        @ability = Ability.new(@user)
        @ability.should be_can(:create, ReviewDecision, @session)
        @ability.should be_cannot(:create, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_can(:create, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:create, ReviewDecision)
      end
      
      it "- session is in review" do
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:create, ReviewDecision, @session)
        @ability.should be_cannot(:create, ReviewDecision)
        
        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_can(:create, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:create, ReviewDecision)

        @session.reject
        
        @ability = Ability.new(@user)
        @ability.should be_cannot(:create, ReviewDecision, @session)
        @ability.should be_cannot(:create, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:create, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:create, ReviewDecision)
      end
    end
    
    context "can edit review decision session" do
      before(:each) do
        @session = Factory(:session)
        @session.reviewing
      end
      
      it " if session on organizer's track" do
        @ability.should be_cannot(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
        
        Factory(:organizer, :track => @session.track, :user => @user)

        @ability = Ability.new(@user)
        @ability.should be_cannot(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
      end
      
      it "if session was not confirmed by author" do
        @session.tentatively_accept
        @session.accept

        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_cannot(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
      end

      it "unless session was rejected by author" do
        @session.tentatively_accept
        
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:update, ReviewDecision, @session)

        @session.reject
        @session.author_agreement = true;
        @session.save
        
        @ability.should be_cannot(:update, ReviewDecision, @session)
      end
      
      it "unless session was accepted by author" do
        @session.tentatively_accept
        
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:update, ReviewDecision, @session)

        @session.accept
        @session.author_agreement = true;
        @session.save
        
        @ability.should be_cannot(:update, ReviewDecision, @session)
      end
      
      it "if session has a review decision" do
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_cannot(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_cannot(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
      end
      
      it "if session is rejected" do
        @session.reject
        
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)
        
        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_can(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
      end
      
      it "if session is tentatively accepted" do
        @session.tentatively_accept
        
        Factory(:organizer, :track => @session.track, :user => @user)
        @ability.should be_can(:update, ReviewDecision, @session)
        @ability.should be_cannot(:update, ReviewDecision)
        
        @ability = Ability.new(@user, :session_id => @session.to_param) # session id provided
        @ability.should be_can(:update, ReviewDecision)

        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil}) # session id nil
        @ability.should be_cannot(:update, ReviewDecision)
      end
    end
  end

  context "- reviewer" do
    before(:each) do
      @user.add_role "reviewer"
      @ability = Ability.new(@user)
    end

    it_should_behave_like "all users"
    
    it "cannot read organizers" do
      @ability.should be_cannot(:read, Organizer)
    end

    it "cannot read other reviewers" do
      @ability.should be_cannot(:read, Reviewer)
    end
    
    it "cannot read organizer's sessions" do
      @ability.should be_cannot(:read, 'organizer_sessions')
    end

    it "can read sessions to review" do
      @ability.should be_can(:read, 'reviewer_sessions')
    end
    
    it "can read reviews listing" do
      @ability.should be_can(:read, 'reviews_listing')
      @ability.should be_can(:reviewer, 'reviews_listing')
    end
    
    it "cannot index all reviews of any session" do
      @ability.should be_cannot(:index, Review)
    end

    it "cannot index all organizer reviews of any session" do
      @ability.should be_cannot(:organizer, Review)
    end

    it "can show own reviews" do
      review = Factory(:review)
      @ability.should be_cannot(:show, review)
      review.reviewer = @user
      @ability.should be_can(:show, review)
    end

    context "can create a new review if:" do
      before(:each) do
        @session = Factory(:session)
        Session.stubs(:for_reviewer).with(@user).returns([@session])
      end
      
      it "has not created a review for this session" do
        @ability.should be_can(:create, Review, @session)
      
        Session.expects(:for_reviewer).with(@user).returns([])
        @ability.should be_cannot(:create, Review, @session)
      end
      
      it "has a session available to add the review to" do
        @ability.should be_cannot(:create, Review)
        @ability.should be_cannot(:create, Review, nil)
        
        @ability = Ability.new(@user, :session_id => @session.to_param)
        @ability.should be_can(:create, Review)
        @ability.should be_can(:create, Review, nil)
        @ability.should be_can(:create, Review, @session)
        
        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:create, Review)
        @ability.should be_cannot(:create, Review, nil)
      end
      
      it "is admin and has a session" do
        @user.add_role('admin')
        
        @ability.should be_cannot(:create, Review)
        @ability.should be_cannot(:create, Review, nil)
        
        @ability = Ability.new(@user, :session_id => @session.to_param)
        @ability.should be_can(:create, Review)
        @ability.should be_can(:create, Review, nil)
        @ability.should be_can(:create, Review, @session)
        
        @ability = Ability.new(@user, {:locale => 'pt', :session_id => nil})
        @ability.should be_cannot(:create, Review)
        @ability.should be_cannot(:create, Review, nil)
      end
    end
  end
end
