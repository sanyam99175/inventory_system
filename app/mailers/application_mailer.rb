class ApplicationMailer < ActionMailer::Base
  default from: "notifications@stockflow.com"
  layout "mailer"
end
