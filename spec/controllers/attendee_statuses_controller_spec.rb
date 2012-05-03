require 'spec_helper'

describe AttendeeStatusesController do
  render_views

  describe "GET show" do
    it "should render show template" do
      attendee = Factory(:attendee, :registration_date => Time.zone.local(2012, 4, 25))
      get :show, :id => attendee.uri_token
      response.should render_template(:show)
      assigns(:attendee).should == attendee
    end
  end
end
