package;
import flash.display.DisplayObject;
import flash.text.TextFieldType;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import openfl.utils.AssetType;
import openfl.events.Event;
import polymod.library.ModAssetLibrary;
import sys.FileSystem;

/**
 * ...
 * @author 
 */
class Demo extends Sprite
{
	private var bees:Array<Bee>;
	private var flowers:Array<Flower>;
	private var home:Home;
	private var time:Float=0;
	private var score:TextField;
	
	public var numBees:Int = 10;
	public var numFlowers:Int = 30;
	public var scripts:MyScriptRunner;

	public function new() 
	{
		super();
		scripts = new MyScriptRunner();
		
		bees = [];
		flowers = [];

		numBees = loadInt("bees.txt");
		numFlowers = loadInt("flowers.txt");

		if(numBees <= 0) numBees = 1;
		if(numFlowers <= 0) numFlowers = 30;

		init();

		score = new TextField();
		addChild(score);
		score.text = "Honey collected: 0";

		Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
	}

	public function loadInt(file:String):Int
	{
		var str = Assets.getText("data/"+file);
		if(str != null && str != "")
		{
			var i = Std.parseInt(str);
			if(i == null)
			{
				i = 0;
			}
			return i;
		}
		return 0;
	}

	public function destroy()
	{
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		for(i in 0...numChildren)
		{
			removeChildAt(0);
		}
		bees = null;
		flowers = null;
	}

	private function onEnterFrame(e:Event)
	{
		var now = Lib.getTimer();
		var elapsed:Float = (now-time)/1000;
		time = now;
		
		for(bee in bees)
		{
			updateBee(bee, elapsed);
		}

		for(flower in flowers)
		{
			updateFlower(flower, elapsed);
		}
	}

	private function init()
	{
		scripts.init.set("Std",Std);
		scripts.init.set("Math",Math);
		scripts.init.set("numFlowers",numFlowers);
		scripts.init.set("numBees",numBees);
		scripts.init.set("distTest",distTest);
		scripts.init.set("makeFlower",makeFlower);
		scripts.init.set("makeHome",makeHome);
		scripts.init.set("makeBee",makeBee);
		scripts.init.set("home",home);
		scripts.init.execute();
	}

	private function updateFlower(flower:Flower, elapsed:Float)
	{
		scripts.updateFlower.set("flower",flower);
		scripts.updateFlower.set("elapsed",elapsed);
		scripts.updateFlower.execute();
	}

	private function updateScore(f:Float)
	{
		scripts.updateScore.set("value",f);
		score.text = scripts.updateScore.execute();
	}

	private function updateBee(bee:Bee, elapsed:Float)
	{
		scripts.updateBee.set("Math",Math);
		scripts.updateBee.set("bee",bee);
		scripts.updateBee.set("elapsed",elapsed);
		scripts.updateBee.set("home",home);
		scripts.updateBee.set("moveToward",moveToward);
		scripts.updateBee.set("isTouching",isTouching);
		scripts.updateBee.set("getClosestFlower",getClosestFlower);
		scripts.updateBee.set("getRandomFlower",getRandomFlower);
		scripts.updateBee.set("emptyFlower",emptyFlower);
		scripts.updateBee.set("updateScore",updateScore);
		scripts.updateBee.execute();
	}

	private function emptyFlower(flower:Flower)
	{
		scripts.emptyFlower.set("flower",flower);
		scripts.emptyFlower.execute();
	}

	private function distTest(x1:Float,y1:Float,x2:Float,y2:Float,r:Float):Bool
	{
		var dx = (x1-x2);
		var dy = (y1-y2);
		var d2 = (dx*dx)+(dy*dy);
		
		if(d2 <= r*r) return true;
		return false;
	}

	private function isTouching(obj1:Sprite, obj2:Sprite):Bool
	{
		if(obj1 == null || obj2 == null) return false;
		if(distTest(obj1.x+obj1.width/2,obj1.y+obj1.height/2,obj2.x+obj2.width/2,obj2.y+obj2.height/2,obj1.width/3))
		{
			return true;
		}
		return false;
	}

	private function moveToward(mover:Mover, target:Sprite, elapsed:Float)
	{
		mover.move.x = target.x-mover.x;
		mover.move.y = target.y-mover.y;
		mover.move.normalize(1.0);
		
		var targetRotation = Math.atan2(mover.move.y,mover.move.x) * 180 / Math.PI;

		mover.rotation = lerp(mover.rotation, targetRotation + 90, 5.0*elapsed);
		
		mover.x += mover.move.x * mover.speed * elapsed;
		mover.y += mover.move.y * mover.speed * elapsed;
	}

	private function lerp(a:Float, b:Float, amt:Float):Float
	{
		var aAmt = 1.0-amt;
		var bAmt = amt;
		return a*aAmt + b*bAmt;
	}

	private function getClosestFlower(x:Float, y:Float, withMostPollen:Bool=false):Flower
	{
		var bestd2:Float = Math.POSITIVE_INFINITY;
		var bestFlower:Flower = null;
		for(flower in flowers)
		{
			var dx = flower.x-x;
			var dy = flower.y-y;
			var d2 = dx*dx+dy*dy;
			if(d2 <= bestd2) 
			{
				if(withMostPollen)
				{
					if(bestFlower == null || flower.pollen >= bestFlower.pollen)
					{
						bestd2 = d2;
						bestFlower = flower;
					}
				}
				else
				{
					bestd2 = d2;
					bestFlower = flower;
				}
			}
		}
		return bestFlower;
	}
	
	private function getRandomFlower():Flower
	{
		var i:Int = Std.int(Math.random() * flowers.length);
		return flowers[i];
	}

	public function makeHome(x:Float, y:Float):Home
	{
		home = new Home();
		addChild(home);
		home.x = x - home.width/2;
		home.y = y - home.height/2;
		return home;
	}

	public function makeBee(x:Float, y:Float):Bee
	{
		var bee = new Bee();
		bees.push(bee);
		addChild(bee);
		bee.x = x - bee.width/2;
		bee.y = y - bee.height/2;
		return bee;
	}

	public function makeFlower(i:Int, x:Float, y:Float):Flower
	{
		if(i < 0 || i > 3) return null;
		var flower = new Flower(i);
		flowers.push(flower);
		addChild(flower);
		flower.x = x - flower.width/2;
		flower.y = y - flower.height/2;
		return flower;
	}
	
}