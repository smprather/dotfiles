if is_truthy $DPC; then
    # interactive tfo-dpc-int fast-int
    export BS_INTERACTIVE_QUEUE="tfo-dpc-int"
    # batch tfo-dpc-bat fast-bat
    export BS_BATCH_QUEUE="tfo-dpc-bat"
else
    # interactive tfo-ndpc-int
    export BS_INTERACTIVE_QUEUE="interactive"
    # lnx64 tfo-ndpc-bat
    export BS_BATCH_QUEUE="lnx64"
fi
