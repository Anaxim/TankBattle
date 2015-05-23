=begin
TODO
(V) Powerups
(!) Stage changes
(V) Finetune respawning
(V) Consolidate firing into tanks
(!) Consolidate score and upgrades into tanks
=end

require 'gosu'
require_relative 'data/tank'
require_relative 'data/bullet'
require_relative 'data/powerup'

class TankBattle < Gosu::Window
	def initialize
		super 640,480,false
		self.caption = "TankBattle Prototype"
		@first_spawn = false
		@background_image = Gosu::Image.new(self,"assets/backgrounds/level1-bg.jpg",true)
		@powerups = Array.new
		@score_counters = Gosu::Image.new(self,"assets/text/score_counters.png",true)
		
		@instructions = Gosu::Image.new(self,"assets/text/instructions.png",true)
		
		@p1_shots = Array.new
		@p1_losses = 0
		@p1_death_time = 0
		
		@p1_victory = false
		@p1_victory_text = Gosu::Image.new(self,"assets/text/player1wins.png",true)
		
		@p2_shots = Array.new
		@p2_losses = 0
		@p2_death_time = 0
		
		@p2_victory = false
		@p2_victory_text = Gosu::Image.new(self,"assets/text/player2wins.png",true)
		
		@victory_text = Gosu::Image.new(self,"assets/text/below_vic.png",true)
	end
	
	def update
		spawn_in
		
		if @first_spawn
			detect_collisions
			test_victory
			#test_close
			
			@p1_score = Gosu::Image.new(self,"assets/text/score_nums/g#{@p2_losses}.png",true)
			@p2_score = Gosu::Image.new(self,"assets/text/score_nums/r#{@p1_losses}.png",true)
			
			unless @p1_victory || @p2_victory
				respawn
				spawn_powerups
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
		
		@p1_shots.each {|shot| shot.move}
		@p2_shots.each {|shot| shot.move}
	end

	def draw
		@background_image.draw(0,0,0)
		
		unless @first_spawn
			@instructions.draw(0,0,10)
		end
		
		unless @p1 == nil
			@p1.draw
		end
		
		unless @p2 == nil
			@p2.draw
		end
		
		if @first_spawn
			@p1_score.draw(-5,0,10)
			@p2_score.draw(0,0,10)
			@score_counters.draw(0,0,10)
		end
		
		@p1_shots.each {|shot| shot.draw}
		@p2_shots.each {|shot| shot.draw}
		@powerups.each {|pu| pu.draw}
		
		if @p1_victory || @p2_victory
			if @p1_victory
				@p1_victory_text.draw(0,0,10)
			end
			if @p2_victory
				@p2_victory_text.draw(0,0,10)
			end
			@victory_text.draw(0,0,10)
			@powerups = []
		end
	end
	
	#spawn handling
	def spawn_in
		if @first_spawn == false
			if button_down?(Gosu::KbLeftControl) && button_down?(Gosu::KbRightControl)
				@p1 = Tank.new(self,"tank-g",@p1_losses,500)
				@p2 = Tank.new(self,"tank-r",@p2_losses,500)
				@p1.warp(160,240,270)
				@p2.warp(480,240,90)
				@first_spawn = true
				@tick = Gosu::milliseconds
			end
		end
	end

	def spawn_powerups
		powerups = ["speed","fire","shield"]
		while @powerups.size < 6 && Gosu::milliseconds > 5000 + @tick
			@tick = Gosu::milliseconds
			@powerups << PowerUp.new(self,Gosu::random(50,590),Gosu::random(50,430),powerups.sample)
		end
	end
	
	def respawn
		if @p1 == nil && Gosu::milliseconds > 750 + @p1_death_time
			@p1 = Tank.new(self,"tank-g",@p1_losses,500)
			p1_y = Gosu::random(40,440)
			if p1_y < 240
				@p1.warp(Gosu::random(40,160),p1_y,Gosu::random(90,160))
			else
				@p1.warp(Gosu::random(40,160),p1_y,Gosu::random(20,90))
			end
		end
		
		if @p2 == nil && Gosu::milliseconds > 750 + @p2_death_time
			@p2 = Tank.new(self,"tank-r",@p2_losses,500)
			p2_y = Gosu::random(40,440)
			if p2_y < 240
				@p2.warp(Gosu::random(480,600),p2_y,Gosu::random(200,270))
			else
				@p2.warp(Gosu::random(480,600),p2_y,Gosu::random(270,340))
			end
		end
	end
	
	#condition testing
	def test_victory
		unless @p1_victory || @p2_victory
			if @p1_losses == 10
				@p1,@p2 = nil,nil
				@p2_victory = true
				#@victory_time = Gosu::milliseconds
			end
			
			if @p2_losses == 10
				@p1,@p2 = nil,nil
				@p1_victory = true
				#@victory_time = Gosu::milliseconds
			end
		end
	end
	
=begin
	def test_close
		if @p1_victory || @p2_victory
			if Gosu::milliseconds > @victory_time + 2000
				close
			end
		end
	end
=end
	
	#collision testing
	def collision?(object_1, object_2)
		hitbox_1, hitbox_2 = object_1.hitbox, object_2.hitbox
		common_x = hitbox_1[:x] & hitbox_2[:x]
		common_y = hitbox_1[:y] & hitbox_2[:y]
		common_x.size > 0 && common_y.size > 0 
	end
	
	def detect_collisions
		@p2_shots.each do |shot| 
			if @p1 != nil && collision?(shot, @p1)
				if @p1.shield_state == true
					@p2_shots.delete(shot)
					@p1.shield_state = false
				else
					@p2_shots.delete(shot)
					@p1 = nil
					@p1_death_time = Gosu::milliseconds
					@p1_losses += 1
				end
			end
		end
		
		@p1_shots.each do |shot|
			if @p2 != nil && collision?(shot, @p2)
				if @p2.shield_state == true
					@p1_shots.delete(shot)
					@p2.shield_state = false
				else
					@p1_shots.delete(shot)
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
	
	#single press testing
	def button_down(id)
		if id == Gosu::KbEscape
			close
		end
		if @first_spawn			
			if @p1 != nil && id == Gosu::KbLeftControl && Gosu::milliseconds > @p1.reload_start + @p1.reload_end
				@p1.shoot(self,@p1_shots,"p1")
			end
			
			if @p2 != nil && id == Gosu::KbRightControl && Gosu::milliseconds > @p2.reload_start + @p2.reload_end
				@p2.shoot(self,@p2_shots,"p2")
			end
			
			if id == Gosu::KbR
				@powerups = []
				@p1_victory,@p2_victory = false,false
				@p1_losses = 0
				@p1_death_time = 0
				@p1 = Tank.new(self,"tank-g",@p1_losses,500)
				@p1.warp(160,240,270)
				@p2_losses = 0
				@p2_death_time = 0
				@p2 = Tank.new(self,"tank-r",@p2_losses,500)
				@p2.warp(480,240,90)
				@tick = Gosu::milliseconds
			end
		end
	end
end

TankBattle.new.show