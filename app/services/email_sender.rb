class EmailSender
  MAX_RETRIES = 3

  def self.send_with_retry(**args)
    new.send_with_retry(**args)
  end

  def send_with_retry(**args)
    retries = 0

    begin
      SendgridClient.new.send_email(**args)
    rescue => e
      retries += 1
      Rails.logger.error("[EmailSender] failed attempt #{retries}: #{e.message}")

      retry if retries < MAX_RETRIES

      Rails.logger.error("[EmailSender] permanently failed: #{args.inspect}")
    end
  end
end