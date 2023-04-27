import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    {
        text: "What is included in my Northwind Health Plus plan that is not in standard?",
        value: "What is included in my Northwind Health Plus plan that is not in standard?"
    },
    { text: "how many stocks did microsoft repurchased in 2023?", value: "how many stocks did microsoft repurchased in 2023?" },
    { text: "What was Microsoft’s revenue for the nine months that ended on March 31 2023?", value: "What was Microsoft’s revenue for the nine months that ended on March 31 2023?" },
    { text: "What does a Product Manager do?", value: "What does a Product Manager do?
" }
];

interface Props {
    onExampleClicked: (value: string) => void;
}

export const ExampleList = ({ onExampleClicked }: Props) => {
    return (
        <ul className={styles.examplesNavList}>
            {EXAMPLES.map((x, i) => (
                <li key={i}>
                    <Example text={x.text} value={x.value} onClick={onExampleClicked} />
                </li>
            ))}
        </ul>
    );
};
