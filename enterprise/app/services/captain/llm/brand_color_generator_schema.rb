class Captain::Llm::BrandColorGeneratorSchema < RubyLLM::Schema
  array :options, description: 'An array of exactly 3 different color palettes to choose from.' do
    object do
      string :name, description: 'A catchy name for this palette (e.g., Vibrant Ocean, Neon Cyberpunk).'
      string :primary, description: 'The primary brand color in hex format (e.g., #1F93FF).'
      string :text, description: 'The ideal text color for readable contrast against the background (e.g., #FFFFFF or #000000).'
      string :background, description: 'The main background color in hex format (e.g., #1A1E29).'
    end
  end
end
