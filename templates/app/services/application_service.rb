class ApplicationService
  attr_reader :result, :error, :error_code, :message

  def self.call(...)
    new(...).tap(&:call)
  end

  def call
    @success = false
    perform
    @success = true if @error.nil?
  rescue StandardError => e
    Honeybadger.notify(e)
    fail!("An error occurred: #{e.message}", code: :internal_error)
  end

  def success?
    @success == true
  end

  def failure?
    !success?
  end

  private

  def perform
    raise NotImplementedError
  end

  def fail!(message, code: nil)
    @error = message
    @error_code = code
    @success = false
  end
end
