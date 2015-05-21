class Tank
	attr_accessor :x,:y,:angle,:f_speed, :reload_end, :reload_start, :fire_boost, :shield_state
	
	def initialize(window,tank,losses,base_reload)
		@image = Gosu::Image.new(window,"assets/tanks/#{tank}.png",true)
		@x = @y = @vel_x = @vel_y = @angle = 0.0
		@f_speed = 0.65*(1.0+(losses.to_f*0.03))
		@b_speed = 0.4*(1.0+(losses.to_f*0.03))
		@deceleration = 0.6*(1.0+(losses.to_f*0.01))
		@turn_speed = 2.0*(1.0+(losses.to_f*0.01))
		@reload_end = 0
		@reload_start = base_reload
		@speed_boost = false
		@speed_boost_start = 0
		@fire_boost = false
		@fire_boost_start = 0
		@shield_state = false
		@shield = Gosu::Image.new(window,"assets/tanks/shield.png",true)
	end
	
	def draw
		@image.draw_rot(@x,@y,2,@angle)
		if @shield_state == true
			@shield.draw_rot(@x,@y,3,@angle)
		end
	end
	
	#utilities
	def hitbox
		hitbox_x = ((@x - @image.width/2).to_i..(@x + @image.width/2).to_i).to_a
		hitbox_y = ((@y - @image.width/2).to_i..(@y + @image.width/2).to_i).to_a
		{:x => hitbox_x, :y => hitbox_y}
	end
	
	def warp(x,y,angle=0)
		@x,@y,@angle = x,y,angle
	end
	
	#movement and control handling
	def shoot(window,shot,player)
		shot << Bullet.new(window, self, player)
		@reload_end = Gosu::milliseconds
	end
	
	def turn_left
		@angle -= @turn_speed
	end
	
	def turn_right
		@angle += @turn_speed
	end
	
	def accelerate
		@vel_x += Gosu::offset_x(@angle,@f_speed)
		@vel_y += Gosu::offset_y(@angle,@f_speed)
	end
	
	def reverse
		@vel_x -= Gosu::offset_x(@angle,@b_speed)
		@vel_y -= Gosu::offset_y(@angle,@b_speed)
	end
	
	def move
		@x += @vel_x
		@y += @vel_y
		
		#X bounding
		if @x < 20
			@x = 20
		end
		if @x > 620
			@x = 620
		end
		
		#Y bounding
		if @y < 20
			@y = 20
		end
		if @y > 460
			@y = 460
		end
		
		@vel_x *= @deceleration
		@vel_y *= @deceleration
	end
	
	#powerup handling
	def powerup(type)
		case type
		when "speed"
			unless @speed_boots == true
				@speed_boost = true
				@f_speed += 0.15
				@b_speed += 0.15
				@deceleration += 0.05
				@turn_speed += 0.05
			end
			@speed_boost_start = Gosu::milliseconds
		when "fire"
			unless @fire_boost == true
				@fire_boost = true
				@reload_start /= 2
			end
			@fire_boost_start = Gosu::milliseconds
		when "shield"
			unless @shield_state == true
				@shield_state = true
			end
		else
			nil
		end
	end
	
	def powerdown
		if @speed_boost == true && Gosu::milliseconds > 5000 + @speed_boost_start
			@f_speed -= 0.15
			@b_speed -= 0.15
			@deceleration -= 0.05
			@turn_speed -= 0.05
			@speed_boost = false
		end
		if @fire_boost == true && Gosu::milliseconds > 5000 + @fire_boost_start
			@reload_start *= 2
			@fire_boost = false
		end
	end
end