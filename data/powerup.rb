class PowerUp
	def initialize(window,x,y,type)
		@image = Gosu::Image.new(window,"assets/powerups/powerup_#{type}.png",true)
		@x = x
		@y = y
		@type = type
	end
	
	def effect(player)
		player.powerup(@type)
	end
	
	def hitbox
		hitbox_x = ((@x - @image.width/2).to_i..(@x + @image.width/2).to_i).to_a
		hitbox_y = ((@y - @image.width/2).to_i..(@y + @image.width/2).to_i).to_a
		{:x => hitbox_x, :y => hitbox_y}
	end
	
	def draw
		@image.draw(@x,@y,1)
	end
end