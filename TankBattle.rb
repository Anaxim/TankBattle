require 'gosu'

class Tank
	attr_accessor :x,:y,:angle
	
	def initialize(window,tank)
		@image = Gosu::Image.new(window,"assets/tanks/#{tank}.png",true)
		@x = @y = @vel_x = @vel_y = @angle = 0.0
	end
	
	def warp(x,y)
		@x,@y = x,y
	end
	
	def turn_left
		@angle -= 1.5
	end
	
	def turn_right
		@angle += 1.5
	end
	
	def accelerate
		@vel_x += Gosu::offset_x(@angle,0.5)
		@vel_y += Gosu::offset_y(@angle,0.5)
	end
	
	def reverse
		@vel_x -= Gosu::offset_x(@angle,0.5)
		@vel_y -= Gosu::offset_y(@angle,0.5)
	end
		
	def move
		@x += @vel_x
		@y += @vel_y
		@x %= 640
		@y %= 480
		
		@vel_x *= 0.5
		@vel_y *= 0.5
	end
	
	def draw
		@image.draw_rot(@x,@y,2,@angle)
	end
end

class Bullet
	def initialize(window,tank)
		@bullet = Gosu::Image.new(window,"assets/ammo/bullet.png",true)
		radians = (tank.angle - 90) * Math::PI / 180.0
		@x = tank.x + (Math.sin(radians))
		@y = tank.y + (Math.cos(radians))
		@angle = tank.angle
		@speed = 5
	end
	
	def draw
		@bullet.draw_rot(@x,@y,1,@angle,0.3,1.7)
	end
	
	def move
		@x += @speed*Math.sin(Math::PI/180*@angle)
		@y += -@speed*Math.cos(Math::PI/180*@angle)
		@x %= 640
		@y %= 480
	end
end

class TankBattle < Gosu::Window
	def initialize
		super 640,480,false
		self.caption = "TankBattle Prototype"
		
		@background_image = Gosu::Image.new(self,"assets/backgrounds/level1-bg.jpg",true)
		@player1 = Tank.new(self,"tank-g")
		@player1.warp(160,240)
		@player2 = Tank.new(self,"tank-r")
		@player2.warp(480,240)
		@shots = Array.new
	end
	
	def update
		if button_down? Gosu::KbA then
			@player1.turn_left
		end
		if button_down? Gosu::KbD then
			@player1.turn_right
		end
		if button_down? Gosu::KbW then
			@player1.accelerate
		end
		if button_down? Gosu::KbS then
			@player1.reverse
		end
		
		if button_down? Gosu::KbLeft then
			@player2.turn_left
		end
		if button_down? Gosu::KbRight then
			@player2.turn_right
		end
		if button_down? Gosu::KbUp then
			@player2.accelerate
		end
		if button_down? Gosu::KbDown then
			@player2.reverse
		end
		
		
		@player1.move
		@player2.move
		
		@shots.each {|shot| shot.move}
	end
		
	def draw
		@player1.draw
		@player2.draw
		@background_image.draw(0,0,0)
		@shots.each {|shot| shot.draw}
	end
	
	def button_down(id)
		if id == Gosu::KbEscape
			close
		end
		if id == Gosu::KbQ
			@shots << Bullet.new(self,@player1)
		end
	end

end

TankBattle.new.show