require 'spec/spec_helper'

describe EmailNotifications do
  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    I18n.locale = I18n.default_locale
  end

  after do
    ActionMailer::Base.deliveries.clear
  end

  context "user subscription" do
    before(:each) do
      @user = Factory(:user)
    end
    
    it "should include account details" do
      mail = EmailNotifications.deliver_welcome(@user)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Nome de usuário.*#{@user.username}/
  	  mail.subject.should == "[localhost:3000] Cadastro realizado com sucesso"
    end
    
    it "should be sent in user's default language" do
      @user.default_locale = 'en'
      mail = EmailNotifications.deliver_welcome(@user)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Username.*#{@user.username}/
  	  mail.subject.should == "[localhost:3000] Account registration"
    end
  end

  context "password reset" do
    before(:each) do
      @user = Factory(:user)
    end
    
    it "should include link with perishable_token" do
      @user.reset_perishable_token!
      mail = EmailNotifications.deliver_password_reset_instructions(@user)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /\/password_resets\/#{@user.perishable_token}\/edit/
  	  mail.subject.should == "[localhost:3000] Recuperação de senha"
    end
    
    it "should be sent in user's default language" do
      @user.default_locale = 'en'
      @user.reset_perishable_token!
      mail = EmailNotifications.deliver_password_reset_instructions(@user)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /\/password_resets\/#{@user.perishable_token}\/edit/
  	  mail.subject.should == "[localhost:3000] Password reset"
    end
  end

  context "session submission" do
    before(:each) do
      @session = Factory(:session)
    end
    
    it "should be sent to first author" do
      mail = EmailNotifications.deliver_session_submitted(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Olá #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
  	  mail.subject.should == "[localhost:3000] Proposta de sessão submetida para #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to second author, if available" do
      user = Factory(:user)
      @session.second_author = user
      
      mail = EmailNotifications.deliver_session_submitted(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Olá #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
  	  mail.subject.should == "[localhost:3000] Proposta de sessão submetida para #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to first author in default language" do
      @session.author.default_locale = 'en'
      mail = EmailNotifications.deliver_session_submitted(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
  	  mail.subject.should == "[localhost:3000] #{AppConfig[:conference_name]} session proposal submitted"
    end

    it "should be sent to second author, if available (in first author's default language)" do
      @session.author.default_locale = 'en'
      user = Factory(:user, :default_locale => 'fr')
      @session.second_author = user
      
      mail = EmailNotifications.deliver_session_submitted(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
  	  mail.subject.should == "[localhost:3000] #{AppConfig[:conference_name]} session proposal submitted"
    end
    
  end

  context "reviewer invitation" do
    before(:each) do
      @reviewer = Factory.build(:reviewer, :id => 3)
    end
    
    it "should include link with invitation" do
      mail = EmailNotifications.deliver_reviewer_invitation(@reviewer)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@reviewer.user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /\/reviewers\/3\/accept/
  	  mail.body.should =~ /\/reviewers\/3\/reject/
  	  mail.subject.should == "[localhost:3000] Convite para equipe de avaliação da #{AppConfig[:conference_name]}"
    end

    it "should be sent in user's default language" do
      @reviewer.user.default_locale = 'en'
      mail = EmailNotifications.deliver_reviewer_invitation(@reviewer)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@reviewer.user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /\/reviewers\/3\/accept/
  	  mail.body.should =~ /\/reviewers\/3\/reject/
  	  mail.subject.should == "[localhost:3000] Invitation to be part of #{AppConfig[:conference_name]} review committee"
    end
  end
  
  context "notification of acceptance" do
    before(:each) do
      @decision = Factory.build(:review_decision, :outcome => Outcome.find_by_title('outcomes.accept.title'))
      @decision.session.update_attribute(:state, "in_review")
      @decision.save
      @session = @decision.session
    end
    
    it "should not be sent if session has no decision" do
      session = Factory(:session)
      lambda {EmailNotifications.deliver_notification_of_acceptance(session)}.should raise_error("Notification can't be sent before decision has been made")
    end
    
    it "should not be sent if session has been rejected" do
      @session.review_decision.expects(:rejected?).returns(true)
      
      lambda {EmailNotifications.deliver_notification_of_acceptance(@session)}.should raise_error("Cannot accept a rejected session")
    end
    
    it "should make review published" do
      @decision.should_not be_published
      EmailNotifications.deliver_notification_of_acceptance(@session)
      @decision.reload.should be_published
    end
    
    it "should be sent to first author" do
      mail = EmailNotifications.deliver_notification_of_acceptance(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Caro #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/confirm/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/withdraw/
  	  
  	  mail.subject.should == "[localhost:3000] Comunicado do Comitê de Programa da #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to second author, if available" do
      user = Factory(:user)
      @session.second_author = user
      
      mail = EmailNotifications.deliver_notification_of_acceptance(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Caros #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/confirm/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/withdraw/

  	  mail.subject.should == "[localhost:3000] Comunicado do Comitê de Programa da #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to first author in default language" do
      @session.author.default_locale = 'en'
      mail = EmailNotifications.deliver_notification_of_acceptance(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/confirm/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/withdraw/
      
  	  mail.subject.should == "[localhost:3000] Notification from the Program Committee of #{AppConfig[:conference_name]}"
    end

    it "should be the same to both authors, if second autor is available" do
      @session.author.default_locale = 'en'
      user = Factory(:user, :default_locale => 'fr')
      @session.second_author = user
      
      mail = EmailNotifications.deliver_notification_of_acceptance(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/confirm/
      mail.body.should =~ /\/sessions\/#{@session.to_param}\/withdraw/

  	  mail.subject.should == "[localhost:3000] Notification from the Program Committee of #{AppConfig[:conference_name]}"
    end
    
  end
  
  context "notification of rejection" do
    before(:each) do
      @decision = Factory.build(:review_decision, :outcome => Outcome.find_by_title('outcomes.reject.title'))
      @decision.session.update_attribute(:state, "in_review")
      @decision.save
      @session = @decision.session
    end
    
    it "should not be sent if session has no decision" do
      session = Factory(:session)
      lambda {EmailNotifications.deliver_notification_of_rejection(session)}.should raise_error("Notification can't be sent before decision has been made")
    end
    
    it "should not be sent if session has been accepted" do
      @session.review_decision.expects(:accepted?).returns(true)
      
      lambda {EmailNotifications.deliver_notification_of_rejection(@session)}.should raise_error("Cannot reject an accepted session")
    end

    it "should make review published" do
      @decision.should_not be_published
      EmailNotifications.deliver_notification_of_rejection(@session)
      @decision.reload.should be_published
    end    

    it "should be sent to first author" do
      mail = EmailNotifications.deliver_notification_of_rejection(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Caro #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
  	  
  	  mail.subject.should == "[localhost:3000] Comunicado do Comitê de Programa da #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to second author, if available" do
      user = Factory(:user)
      @session.second_author = user
      
      mail = EmailNotifications.deliver_notification_of_rejection(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Caros #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/

  	  mail.subject.should == "[localhost:3000] Comunicado do Comitê de Programa da #{AppConfig[:conference_name]}"
    end
    
    it "should be sent to first author in default language" do
      @session.author.default_locale = 'en'
      mail = EmailNotifications.deliver_notification_of_rejection(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/
      
  	  mail.subject.should == "[localhost:3000] Notification from the Program Committee of #{AppConfig[:conference_name]}"
    end

    it "should be the same to both authors, if second autor is available" do
      @session.author.default_locale = 'en'
      user = Factory(:user, :default_locale => 'fr')
      @session.second_author = user
      
      mail = EmailNotifications.deliver_notification_of_rejection(@session)
      ActionMailer::Base.deliveries.size.should == 1
      mail.to.should == [@session.author.email, user.email]
      mail.content_type.should == "multipart/alternative"
  	  mail.body.should =~ /Dear #{@session.author.full_name} &amp; #{user.full_name},/
  	  mail.body.should =~ /#{@session.title}/
  	  mail.body.should =~ /\/sessions\/#{@session.to_param}/

  	  mail.subject.should == "[localhost:3000] Notification from the Program Committee of #{AppConfig[:conference_name]}"
    end
    
  end
end
