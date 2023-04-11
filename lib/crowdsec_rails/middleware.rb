module CrowdsecRails
  class Middleware
    @@error_counter = Hash.new(0)
    ERROR_THRESHOLD = 5
    TIME_WINDOW = 60

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      request = Rack::Request.new(env)
      ip = request.ip

      if detect_null_bytes(request.params)
        # TODO
        alert_data = [
          {
            source: {
              ip: ip,
            }
          }
        ]
        notifier = CrowdsecNotifier.new
        notifier.send_alert(alert_data)
      end

      if status.eql?(500) && detect_suspect_activity(ip)
        # TODO
        alert_data = [
          {
            source: {
              ip: ip,
            }
          }
        ]
        notifier = CrowdsecNotifier.new
        notifier.send_alert(alert_data)
      end

      [status, headers, body]
    end

    def detect_null_bytes(params)
      params.values.any? { |value| value.is_a?(String) && value.include?("\x00") }
    end

    def detect_suspect_activity(ip)
      now = Time.now.to_i

      # Removes obsolete entries
      @@error_counter.delete_if { |_key, value| value[:last_seen] < now - TIME_WINDOW }

      # Increment the error counter for the given IP
      @@error_counter[ip][:count] += 1
      @@error_counter[ip][:last_seen] = now

      # Checks if the number of errors exceeds the threshold in the time window
      if @@error_counter[ip][:count] >= ERROR_THRESHOLD
        @@error_counter.delete(ip)
        return true
      end

      false
    end
  end
end
