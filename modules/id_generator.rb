module IdGenerator
  def self.create_id
    return SecureRandom.alphanumeric(8)
  end
end
