=begin
TODO
(?) Consolidate movement code in Window
(?) Dedicated player nil check
(V) Powerups
(!) Stage changes
(V) Finetune respawning
(!) Consolidate shots and firing into tanks
(!) Consolidate score and upgrades into tanks
=end

require 'gosu'

class Tank
	attr_accessor :x,:y,:angle,:f_speed, :reload_end, :reload_start, :fire_boost, :shield_state
	
	def initialize(window,tank,losses)
		@image = Gosu::Image.new(window,"assets/tanks/#{tank}.png",true)
		@x = @y = @vel_x = @vel_y = @angle = 0.0
		@f_speed = 0.65*(1.0+(losses.to_f*0.03))
		@b_speed = 0.4*(1.0+(losses.to_f*0.03))
		@deceleration = 0.6*(1.0+(losses.to_f*0.01))
		@turn_speed = 2.0*(1.0+(losses.to_f*0.01))
		@reload_end = 0
		@reload_start = 500
		@speed_boost = false
		@speed_boost_start = 0
		@fire_boost = false
		@fire_boost_start = 0
		@shield_state = false
		@shield = Gosu::Image.new(window,"assets/tanks/shield.png",true)
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
	
	def draw
		@image.draw_rot(@x,@y,2,@angle)
		if @shield_state == true
			@shield.draw_rot(@x,@y,3,@angle)
		end
	end
end

class Bullet
	attr_accessor :tank
	
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
		@image.draw_rot(@x,@y,1,0)
	end
end

class TankBattle < Gosu::Window
	def initialize
		super 640,480,false
		self.caption = "TankBattle Prototype"
		
		@background_image = Gosu::Image.new(self,"assets/backgrounds/level1-bg.jpg",true)
		@powerups = Array.new
		@tick = 0
		
		@shots_1 = Array.new
		@p1_losses = 0
		@p1_death_time = 0
		
		@shots_2 = Array.new
		@p2_losses = 0
		@p2_death_time = 0
		
		@p1_score = Gosu::Font.new(self, Gosu::default_font_name, 20)
		@p2_score = Gosu::Font.new(self, Gosu::default_font_name, 20)
		
		@victory_text = Gosu::Font.new(self, Gosu::default_font_name, 100)
		
		@p1_victory = false
		@p2_victory = false
		
		@first_spawn = false
		@victory_time = 0
	end
	
	def spawn_in
		if @first_spawn == false
			if button_down?(Gosu::KbLeftControl) && button_down?(Gosu::KbRightControl)
				@p1 = Tank.new(self,"tank-g",0)
				@p2 = Tank.new(self,"tank-r",0)
				@p1.warp(160,240,270)
				@p2.warp(480,240,90)
				@first_spawn = true
			end
		end
	end
	
	
	def update
		spawn_in
		detect_collisions
		test_victory
		test_close
		
		if @first_spawn
			spawn_powerups
			unless @p1_victory || @p2_victory
				respawn
			end
			
			unless @p1 == nil
				if button_down? Gosu::KbA then
					@p1.turn_left
				end
				if button_down? Gosu::KbD then
					@p1.turn_right
				end
				if button_down? Gosu::KbW then
					@p1.accelerate
				end
				if button_down? Gosu::KbS then
					@p1.reverse
				end
				@p1.move
				@p1.powerdown
			end
		
			unless @p2 == nil
				if button_down? Gosu::KbLeft then
					@p2.turn_left
				end
				if button_down? Gosu::KbRight then
					@p2.turn_right
				end
				if button_down? Gosu::KbUp then
					@p2.accelerate
				end
				if button_down? Gosu::KbDown then
					@p2.reverse
				end
				@p2.move
				@p2.powerdown
			end
		end
		
		@shots_1.each {|shot| shot.move}
		@shots_2.each {|shot| shot.move}
	end
	
	def spawn_powerups
		powerups = ["speed","fire","shield"]
		while @powerups.size < 6 && Gosu::milliseconds > 5000 + @tick
			@tick = Gosu::milliseconds
			@powerups << PowerUp.new(self,Gosu::random(50,590),Gosu::random(50,430),powerups.sample)
		end
	end
	
	
	def test_close
		if @p1_victory || @p2_victory
			if Gosu::milliseconds > @victory_time + 2000
				close
			end
		end
	end
	
	def respawn
		if @p1 == nil && Gosu::milliseconds > 750 + @p1_death_time
			@p1 = Tank.new(self,"tank-g",@p1_losses)
			p1_y = Gosu::random(40,440)
			if p1_y < 240
				@p1.warp(Gosu::random(40,160),p1_y,Gosu::random(90,160))
			else
				@p1.warp(Gosu::random(40,160),p1_y,Gosu::random(20,90))
			end
		end
		
		if @p2 == nil && Gosu::milliseconds > 750 + @p2_death_time
			@p2 = Tank.new(self,"tank-r",@p2_losses)
			p2_y = Gosu::random(40,440)
			if p2_y < 240
				@p2.warp(Gosu::random(480,600),p2_y,Gosu::random(200,270))
			else
				@p2.warp(Gosu::random(480,600),p2_y,Gosu::random(270,340))
			end
		end
	end
		
	def collision?(object_1, object_2)
		hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
		common_x = hitbox_1[:x] & hitbox_2[:x]
		common_y = hitbox_1[:y] & hitbox_2[:y]
		common_x.size > 0 && common_y.size > 0 
	end
	
	def detect_collisions
		@shots_2.each do |shot| 
			if @p1 != nil && collision?(shot, @p1)
				if @p1.shield_state == true
					@shots_2.delete(shot)
					@p1.shield_state = false
				else
					@shots_2.delete(shot)
					@p1 = nil
					@p1_death_time = Gosu::milliseconds
					@p1_losses += 1
				end
			end
		end
		
		@shots_1.each do |shot|
			if @p2 != nil && collision?(shot, @p2)
				if @p2.shield_state == true
					@shots_1.delete(shot)
					@p2.shield_state = false
				else
					@shots_1.delete(shot)
					@p2 = nil
					@p2_death_time = Gosu::milliseconds
					@p2_losses += 1
				end
			end
		end
		
		@powerups.each do |pu|
			if @p1 != nil && collision?(@p1,pu)
				@powerups.delete(pu)
				pu.effect(@p1)
			end
			if @p2 != nil && collision?(@p2,pu)
				@powerups.delete(pu)
				pu.effect(@p2)
			end
		end
		
		
		if @p1 != nil && @p2 != nil && collision?(@p1,@p2)
			@p1,@p2 = nil,nil
		end
	end
	
	def test_victory
		unless @p1_victory || @p2_victory
			if @p1_losses == 10
				@p1,@p2 = nil,nil
				@p2_victory = true
				@victory_time = Gosu::milliseconds
			end
			
			if @p2_losses == 10
				@p1,@p2 = nil,nil
				@p1_victory = true
				@victory_time = Gosu::milliseconds
			end
		end
	end
		
	def draw
		@background_image.draw(0,0,0)
		
		unless @p1 == nil
			@p1.draw
		end
		
		unless @p2 == nil
			@p2.draw
		end
		
		@p1_score.draw("P1 Score: #{@p2_losses}", 10, 10, 10)
		@p2_score.draw("P2 Score: #{@p1_losses}", 530, 10, 10)
				
		@shots_1.each {|shot| shot.draw}
		@shots_2.each {|shot| shot.draw}
		@powerups.each {|pu| pu.draw}
		
		if @p1_victory
			@victory_text.draw_rel("Player 1 wins!!!",320,240,10,0.5,0.5)
		end
		if @p2_victory
			@victory_text.draw_rel("Player 2 wins!!!",320,240,10,0.5,0.5)
		end
	end
		
	def button_down(id)
		if id == Gosu::KbEscape
			close
		end
		if @first_spawn
			if id == Gosu::KbM
				@p1.shield_state, @p2.shield_state = true, true
			end
			
			if @p1 != nil && id == Gosu::KbLeftControl && Gosu::milliseconds > @p1.reload_start + @p1.reload_end
				@shots_1 << Bullet.new(self,@p1,"p1")
				@p1.reload_end = Gosu::milliseconds
			end
			
			if @p2 != nil && id == Gosu::KbRightControl && Gosu::milliseconds > @p2.reload_start + @p2.reload_end
				@shots_2 << Bullet.new(self,@p2,"p2")
				@p2.reload_end = Gosu::milliseconds
			end
			
			if id == Gosu::KbR
				@p1 = Tank.new(self,"tank-g",0)
				@p1.warp(160,240,90)
				@p1_losses = 0
				@p2 = Tank.new(self,"tank-r",0)
				@p2.warp(480,240,270)
				@p2_losses = 0
				@p1_victory,@p2_victory = false,false
			end
		end
	end
end

TankBattle.new.show