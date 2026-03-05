@tool
extends EditorScript

const USECS_TO_SECS: float = 1_000_000.0

var expression: Expression
# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var current_vol: float = AudioServer.get_bus_volume_linear(0)
	expression = Expression.new()
	expression.parse('Engine.get_singleton("AudioServer").set_bus_volume_linear(0, clampf(value/100.0, 0.0, 1.0))', ["Engine", "value"])
	
	const COUNT: int = 2_000
	#AudioServer.set_bus_volume_linear.bind(0, )
	compare_methods([expression.execute.bind([Engine, current_vol]), update_vol.bind(current_vol)], COUNT)

func update_vol(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, clampf(value/100.0, 0.0, 1.0))

func compare_methods(callables: Array[Callable], call_count: int = 1000) -> void:
	print(" - - - - -")
	for callable: Callable in callables:
		average_benchmark(call_count, callable)
		#print("%s \t => Calls: %5d | Total sec: %01.05f | Average sec: %01.010f" % [callable, count, float(total_usec)/USECS_TO_SECS, avg_sec])

func average_benchmark(count: int, callable: Callable) -> void:
	var total_usec: int = 0
	for i in count:
		total_usec += get_elapsed_usec(callable)
	
	var avg_sec: float = float(total_usec)/float(count)/USECS_TO_SECS 
	print("%s \t\t => Calls: %5d | Total sec: %01.05f | Average sec: %01.010f" % [callable, count, float(total_usec)/USECS_TO_SECS, avg_sec])

func get_elapsed_usec(callable: Callable) -> int:
	var start_time:= Time.get_ticks_usec()
	callable.call()
	return Time.get_ticks_usec() - start_time
	
	#print("Ran callable %s in %01.05f" % [callable, elapsed_sec])
