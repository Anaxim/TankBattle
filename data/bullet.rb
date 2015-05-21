class Bullet
	def initialize(window,tank,player)
		@image = Gosu::Image.new(window,"assets/ammo/bullet_#{player}.png",true)
		radians = (tank.angle - 90) * Math::PI / 180.0
		@x = tank.x + (Math.sin(radians))
		@y = tank.y + (Math.cos(radians))
		@angle = tank.angle
		@speed = 5
		@sound = Gosu::Sample.new(window,"assets/sounds/tanks/laser_#{player}.wav")
		@sound.play
	end
		
	def hitbox
		hitbox_x = ((@x - @image.width/2).to_i..(@x + @image.width/2).to_i).to_a
		hitbox_y = ((@y - @image.width/2).to_i..(@y + @image.width/2).to_i).to_a
		{:x => hitbox_x, :y => hitbox_y}
	end
	
	def draw
		@image.draw_rot(@x,@y,1,@angle,0.5,1.7)
	end
	
	def move
		@x += @speed*Math.sin(Math::PI/180*@angle)
		@y += -@speed*Math.cos(Math::PI/180*@angle)
	end
end