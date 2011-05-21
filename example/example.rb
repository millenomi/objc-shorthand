require '../objc_shorthand'

objc_class :SomeNiceCell do
	subclass_of :ILNIBTableViewCell
	framework 'UIKit'; import 'ILNIBTableViewCell.h'
	
	nameLabel :UILabel, :outlet, :did_set
	surnameLabel :UILabel, :outlet, :will_set, :did_set
	editDelegate 'id <SomeNiceCellEditDelegate>'
	
	selectedForKilling :bool, :will_set
	age :int
end
