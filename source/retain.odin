package side_scroller

retain :: proc(
	arr: 	^[dynamic]$T,
	keep:	proc(item: T) -> bool,
) {
	for i := 0; i < len(arr); {
		if keep(arr[i]) {
			i += 1
		} else {
			unordered_remove(arr, i)
		}
	}
}