require 'gosu'

class Tank
	attr_accessor :x,:y,:angle
	
	def initialize(window,tank)
		@image = Gosu::Image.new(window,"assets/tanks/#{tank}.png",true)
		@x = @y = @vel_x = @vel_y = @angle = 0.0
	end
	
	
	def hitbox
		hitbox_x = ((@x - @image.width/2).to_i..(@x + @image.width/2).to_i).to_a
		hitbox_y = ((@y - @image.width/2).to_i..(@y + @image.width/2).to_i).to_a
		{:x => hitbox_x, :y => hitbox_y}
	end
	
	def warp(x,y,angle=0)
		@x,@y,@angle = x,y,angle
	end
	
	def turn_left
		@angle -= 2
	end
	
	def turn_right
		@angle += 2
	end
	
	def accelerate
		@vel_x += Gosu::offset_x(@angle,0.65)
		@vel_y += Gosu::offset_y(@angle,0.65)
	end
	
	def reverse
		@vel_x -= Gosu::offset_x(@angle,0.4)
		@vel_y -= Gosu::offset_y(@angle,0.4)
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
		
		@vel_x *= 0.6
		@vel_y *= 0.6
	end
	
	def draw
		@image.draw_rot(@x,@y,2,@angle)
	end
end

class Bullet
	def initialize(window,tank)
		@image = Gosu::Image.new(window,"assets/ammo/bullet.png",true)
		radians = (tank.angle - 90) * Math::PI / 180.0
		@x = tank.x + (Math.sin(radians))
		@y = tank.y + (Math.cos(radians))
		@angle = tank.angle
		@speed = 5
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

class TankBattle < Gosu::Window
	def initialize
		super 640,480,false
		self.caption = "TankBattle Prototype"
		
		@background_image = Gosu::Image.new(self,"assets/backgrounds/level1-bg.jpg",true)
		@players = Array.new
		@players[0] = Tank.new(self,"tank-g")
		@players[0].warp(160,240,90)
		@players[1] = Tank.new(self,"tank-r")
		@players[1].warp(480,240,270)
		@shots_1 = Array.new
		@shots_2 = Array.new
	end
	
	def update
		detect_collisions
		if button_down? Gosu::KbA then
			@players[0].turn_left
		end
		if button_down? Gosu::KbD then
			@players[0].turn_right
		end
		if button_down? Gosu::KbW then
			@players[0].accelerate
		end
		if button_down? Gosu::KbS then
			@players[0].reverse
		end
		
		if button_down? Gosu::KbLeft then
			@players[1].turn_left
		end
		if button_down? Gosu::KbRight then
			@players[1].turn_right
		end
		if button_down? Gosu::KbUp then
			@players[1].accelerate
		end
		if button_down? Gosu::KbDown then
			@players[1].reverse
		end
		
		@players.each {|player| player.move}
		@shots_1.each {|shot| shot.move}
		@shots_2.each {|shot| shot.move}
	end
	
	def collision?(object_1, object_2)
		hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
		common_x = hitbox_1[:x] & hitbox_2[:x]
		common_y = hitbox_1[:y] & hitbox_2[:y]
		common_x.size > 0 && common_y.size > 0 
	end
	
	def detect_collisions
		@shots_2.each do |shot| 
			if collision?(shot, @players[0])
				@shots_2.delete(shot)
				@players.delete(@players[0])
			end
		end
		@shots_1.each do |shot|
			if collision?(shot, @players[1])
				@shots_1.delete(shot)
				@players.delete(@players[1])
			end
		end
	end
	
	def draw
		@players.each {|player| player.draw}
		@background_image.draw(0,0,0)
		@shots_1.each {|shot| shot.draw}
		@shots_2.each {|shot| shot.draw}
	end
		
	def button_down(id)
		if id == Gosu::KbEscape
			close
		end
		if id == Gosu::KbSpace
			@shots_1 << Bullet.new(self,@players[0])
		end
		if id == Gosu::KbRightControl
			@shots_2 << Bullet.new(self,@players[1])
		end
		if id == Gosu::KbR
			if @players.empty? == false
				@players.each {|player| @players.delete(player)}
			end
			
			@players[0] = Tank.new(self,"tank-g")
			@players[0].warp(160,240,90)
			@players[1] = Tank.new(self,"tank-r")
			@players[1].warp(480,240,270)
		end
	end
end

TankBattle.new.show