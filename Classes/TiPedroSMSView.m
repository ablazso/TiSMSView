//
//  PecTfTextField.m
//  textfield
//
//  Created by Pedro Enrique on 7/3/11.
//  Copyright 2011 Appcelerator. All rights reserved.
//

#import "TiPedroSMSView.h"
#import "TiBase.h"
#import "TiUtils.h"
#import "TiHost.h"


@implementation TiPedroSMSView
@synthesize value;
@synthesize firstTime;
@synthesize returnType;
@synthesize font;
@synthesize textColor;
@synthesize textAlignment;
@synthesize autocorrect;
@synthesize beditable;
@synthesize hasCam;

-(void)dealloc
{
	RELEASE_TO_NIL(textArea);
	RELEASE_TO_NIL(scrollView);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	[super dealloc];
}

-(id)init
{
    if(self = [super init])
	{
		self.firstTime = YES;
		self.autocorrect = YES;
		self.beditable = YES;
		self.hasCam = NO;
	}
	return self;
}

#pragma mark UI Elements

-(PESMSTextArea *)textArea 
{
	if(!textArea){
		textArea = [[PESMSTextArea alloc] initWithFrame:self.frame];
		textArea.delegate = self;
	}
	return textArea;
}

-(PESMSScrollView *)scrollView
{
	if(!scrollView)
	{
		CGFloat h = CGRectGetHeight(self.frame);
		CGRect a = self.frame;
		a.size.height = h - 40;
		a.origin.y = 0;
		scrollView = [[PESMSScrollView alloc] initWithFrame:a];
		scrollView.delegate = self;
	}
	return scrollView;
}

#pragma mark Keyboard stuff

//Code from Brett Schumann
-(void) keyboardWillShow:(NSNotification *)note{
    // get keyboard size and loctaion
	CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	
	// get the height since this is the main value that we need.
	NSInteger kbSizeH = keyboardBounds.size.height;
	
	// get a rect for the textView frame
	CGRect containerFrame = [self textArea].frame;
	containerFrame.origin.y -= kbSizeH;
	CGRect scrollViewFrame = [self scrollView].frame;	
	scrollViewFrame.size.height -=kbSizeH;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
	
	// set views with new info
	[self scrollView].frame = scrollViewFrame;
	[self textArea].frame = containerFrame;
	
	// commit animations
	[UIView commitAnimations];
	[[self scrollView] reloadContentSize];
}


-(void) keyboardWillHide:(NSNotification *)note{
    // get keyboard size and location
	CGRect keyboardBounds;
	
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
	
	// get the height since this is the main value that we need.
	NSInteger kbSizeH = keyboardBounds.size.height;
	
	// get a rect for the textView frame
	CGRect containerFrame = [self textArea].frame;
	containerFrame.origin.y += kbSizeH;
	CGRect scrollViewFrame = [self scrollView].frame;	
	scrollViewFrame.size.height +=kbSizeH;
	
	// animations settings
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
	
	// set views with new info
	[[self scrollView]setFrame: scrollViewFrame];
	[[self textArea] setFrame: containerFrame];
	
	// commit animations
	[UIView commitAnimations];
}

-(void)heightOfTextViewDidChange:(float)height
{
	CGRect scrollViewFrame = [self scrollView].frame;	
	scrollViewFrame.size.height +=height;
	[[self scrollView]setFrame: scrollViewFrame];
	[[self scrollView] reloadContentSize];
}

#pragma mark methods to be used in Javascript

-(void)_blur
{
	[[[self textArea] textView] performSelectorOnMainThread:@selector(resignFirstResponder) withObject:nil waitUntilDone:YES];
}
-(void)_focus
{
	[[[self textArea] textView] performSelectorOnMainThread:@selector(becomeFirstResponder) withObject:nil waitUntilDone:YES];
}

-(void)sendImage:(UIImage *)image
{
	[[self scrollView] performSelectorOnMainThread:@selector(sendImage:) withObject:image waitUntilDone:YES];
	[[self scrollView] performSelectorOnMainThread:@selector(reloadContentSize) withObject:nil waitUntilDone:YES];
}
-(void)recieveImage:(UIImage *)image
{
	[[self scrollView] performSelectorOnMainThread:@selector(recieveImage:) withObject:image waitUntilDone:YES];
	[[self scrollView] performSelectorOnMainThread:@selector(reloadContentSize) withObject:nil waitUntilDone:YES];
}

-(void)sendMessage:(NSString *)msg
{
	if([msg isEqualToString:@""])
		return;
	[[self scrollView] performSelectorOnMainThread:@selector(sendMessage:) withObject:msg waitUntilDone:YES];
	[[self scrollView] performSelectorOnMainThread:@selector(reloadContentSize) withObject:nil waitUntilDone:YES];
}

-(void)recieveMessage:(NSString *)msg
{
	if([msg isEqualToString:@""])
		return;
	[[self scrollView] performSelectorOnMainThread:@selector(recieveMessage:) withObject:msg waitUntilDone:YES];
	[[self scrollView] performSelectorOnMainThread:@selector(reloadContentSize) withObject:nil waitUntilDone:YES];
}


#pragma mark Event listeners

-(void)textViewCamButtonPressed:(NSString *)text
{
	NSMutableDictionary *tiEvent = [NSMutableDictionary dictionary];
	[tiEvent setObject:text forKey:@"value"];
	[self.proxy fireEvent:@"camButtonClicked" withObject:tiEvent];
}

-(void)textViewSendButtonPressed:(NSString *)text
{
	NSMutableDictionary *tiEvent = [NSMutableDictionary dictionary];
	[tiEvent setObject:text forKey:@"value"];
	[self.proxy fireEvent:@"buttonClicked" withObject:tiEvent];
	[[self textArea] emptyTextView];
	[[self scrollView] reloadContentSize];
}
-(void)textViewTextChange:(NSString *)text
{
	NSMutableDictionary *tiEvent = [NSMutableDictionary dictionary];
	[tiEvent setObject:text forKey:@"value"];
	[self.proxy fireEvent:@"change" withObject:tiEvent];
	
	self.value = text;
}
-(void)scrollViewClicked:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSMutableDictionary *tiEvent = [NSMutableDictionary dictionary];
	
	[self.proxy fireEvent:@"click" withObject:tiEvent];
	
	[self _blur];
}


-(void)changeHeightOfScrollView
{
	// Empty for now, we don't need this, it is completely useless for the JS app
}

#pragma mark Titanium's resize/init function

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    [TiUtils setView:self positionRect:self.superview.bounds];

    CGRect a = self.frame;
    CGFloat h = CGRectGetHeight(self.frame);
    a.size.height = h - 40;
    [[self scrollView] setFrame:a];
	
	if(self.firstTime)
	{
		self.firstTime = YES;
		[self addSubview: [self scrollView]];
		[self addSubview: [self textArea]];
		
		if(self.returnType)
			[[[self textArea] textView] setReturnKeyType:self.returnType];
		if(self.font)
			[[[self textArea] textView] setFont:[self.font font]];
		if(self.textColor)
			[[[self textArea] textView] setTextColor:[self.textColor _color]];
		if(self.textAlignment)
			[[[self textArea] textView] setTextAlignment:self.textAlignment];
		if(self.value)
			[[[self textArea] textView]setText:self.value];
		
		[[self textArea] setCamera:self.hasCam];
		[[[self textArea] textView] setEditable:self.beditable];
		[[[self textArea] textView] setAutocorrectionType:self.autocorrect ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo];
		[[[self textArea] textView] setDataDetectorTypes:UIDataDetectorTypeAll];
	}
    else
    {
        [[self scrollView] reloadContentSize];
        [[self textArea] resize];
    }
	
}

#pragma mark Titanium's setters

-(void)setCamButton_:(id)args
{
	self.hasCam = [TiUtils boolValue:args];
	if(!self.firstTime)
	{
		[[self textArea] setCamera:self.hasCam];
		[[self textArea] resize];
	}
}	

-(void)setSendColor_:(id)col
{
    [[self scrollView] performSelectorOnMainThread:@selector(sendColor:) withObject:[TiUtils stringValue:col] waitUntilDone:YES];
}

-(void)setRecieveColor_:(id)col
{
    [[self scrollView] performSelectorOnMainThread:@selector(recieveColor:) withObject:[TiUtils stringValue:col] waitUntilDone:YES];
	
}

-(void)setButtonTitle_:(id)title
{
	[[self textArea] buttonTitle:[TiUtils stringValue:title]];
	[[self scrollView] reloadContentSize];
}

-(void)setReturnKeyType_:(id)val
{
	self.returnType = [TiUtils intValue:val];
	if(!self.firstTime)
		[[[self textArea] textView] setReturnKeyType:self.returnType];
}

-(void)setFont_:(id)val
{
	self.font = [TiUtils fontValue:val def:nil];
	if(!self.firstTime)
		[[[self textArea] textView] setFont:[self.font font]];
}

-(void)setTextColor_:(id)val
{
	self.textColor = [TiUtils colorValue:val];
	if(!self.firstTime)
		[[[self textArea] textView] setTextColor:[self.textColor _color]];
}

-(void)setTextAlignment_:(id)val
{
	self.textAlignment = [TiUtils textAlignmentValue:val];
	if(!self.firstTime)
		[[[self textArea] textView] setTextAlignment:self.textAlignment];
}

-(void)setAutocorrect_:(id)val
{
	self.autocorrect = [TiUtils boolValue:val];
	if(!self.firstTime)
		[[[self textArea] textView ]setAutocorrectionType:[TiUtils boolValue:val] ? UITextAutocorrectionTypeYes : UITextAutocorrectionTypeNo];
}

-(void)setEditable_:(id)val
{
	self.beditable = [TiUtils boolValue:val];
	if(!self.firstTime)
		[[[self textArea] textView] setEditable:self.beditable];
}

-(void)setValue_:(id)val
{
	self.value = [TiUtils stringValue:val];
	if(!self.firstTime)
		[[[self textArea] textView]setText:self.value];
}

-(void)setAnimated_:(id)args
{
	[[self scrollView] animate:[TiUtils boolValue:args]];	
}

 
@end
