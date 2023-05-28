class Settings
  def self.set_environment(environment)
    @@env = environment
  end

  def self.development?
    @@env == :development
  end

  def self.production?
    @@env == :production
  end
end

def development?
  Settings.development?
end

def production?
  Settings.production?
end
