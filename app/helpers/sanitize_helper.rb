# note: not currently needed, but might be useful later for more nuanced sanitizing?

module SanitizeHelper
	class CommentScrubber < Rails::Html::PermitScrubber
	  def initialize
	    super
	    self.tags = %w( figcaption figure img pre p table td tr th tbody li ul ol span div code b i br strong em a legend h1 h2 h3 h4 h5 )
	    self.attributes = %w( src href class style target )
	  end

	  def allowed_node?(node)
	  	puts(node.name)
	    node.name == "textarea" || node.name.include?("http")
	  end

	  def skip_node?(node)
	  	node.name.include?("http")
	  end

	end
end